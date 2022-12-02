pragma solidity 0.8.17;

import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DiebetesMain {
    error INVALID_CONTRIBUTOR();
    error INVALID_PROPOSAL_OWNER();
    error PROPOSAL_NOT_CREATED();
    error FUNDS_NOT_AVAILABLE();
    error FUNDING_GOAL_ALREADY_REACHED();
    error FUNDING_GOAL_NOT_REACHED();

    // Swap the domain ID
    uint32 public constant DOMAIN_ID = 9991;

    // The connext contract on the origin domain.
    IConnext public immutable connext;

    IERC20 public immutable token;

    uint256 public numProposals;

    struct FundingInfo {
        address proposalOwner;
        string ipfsURl;
        uint128 fundingTarget;
        uint128 fundingReceived;
    }

    mapping(uint256 => FundingInfo) public fundingInfoOf;

    mapping(address => mapping(address => uint256)) public contributionOf;

    constructor(IConnext _connext, IERC20 _token) {
        connext = _connext;
        token = _token;
    }

    function createFundingProposal(
        uint128 _fundingTarget,
        string memory ipfsURl
    ) external {
        numProposals += 1;
        fundingInfoOf[numProposals] = FundingInfo({
            proposalOwner: msg.sender,
            ipfsURl: ipfsURl,
            fundingTarget: _fundingTarget,
            fundingReceived: 0
        });
    }

    function pay(
        address _target,
        uint256 _proposalId,
        uint128 _amount
    ) external {
        FundingInfo storage _fundingInfo = fundingInfoOf[_proposalId];
        if (_fundingInfo.proposalOwner == msg.sender)
            revert INVALID_CONTRIBUTOR();

        if (_fundingInfo.fundingReceived == _fundingInfo.fundingTarget)
            revert FUNDING_GOAL_ALREADY_REACHED();

        _fundingInfo.fundingReceived += _amount;

        contributionOf[msg.sender][_fundingInfo.proposalOwner] += _amount;

        // User sends funds to this contract
        token.transferFrom(msg.sender, address(this), _amount);

        // Include the relayerFee so Pong will use the same fee
        // Include the address of this contract so Pong will know where to send the "callback"
        bytes memory _callData = abi.encode(msg.sender);
        connext.xcall{value: 0}(
            DOMAIN_ID, // _destination: Domain ID of the destination chain
            _target, // _to: address of the target contract (Pong)
            address(0), // _asset: address of the token contract
            msg.sender, // _delegate: address that can revert or forceLocal on destination
            0, // _amount: amount of tokens to transfer
            0, // _slippage: the maximum amount of slippage the user will accept in BPS, in this case 0.3%
            _callData // _callData: the encoded calldata to send
        );
    }

    function withdrawFundingAmount(uint256 _proposalId) external {
        FundingInfo storage _fundingInfo = fundingInfoOf[_proposalId];

        if (msg.sender != _fundingInfo.proposalOwner)
            revert INVALID_PROPOSAL_OWNER();

        if (_fundingInfo.fundingTarget == 0) revert PROPOSAL_NOT_CREATED();

        if (_fundingInfo.fundingReceived != _fundingInfo.fundingTarget)
            revert FUNDING_GOAL_NOT_REACHED();

        _fundingInfo.fundingReceived = 0;

        token.transfer(msg.sender, _fundingInfo.fundingTarget);
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external returns (bytes memory) {
        // Unpack the _callData
        (address _contributor, uint256 _proposalId) = abi.decode(
            _callData,
            (address, uint256)
        );
        FundingInfo storage _fundingInfo = fundingInfoOf[_proposalId];
        if (_fundingInfo.fundingReceived == 0) revert FUNDS_NOT_AVAILABLE();
        uint256 _amountToTransfer = contributionOf[_contributor][
            _fundingInfo.proposalOwner
        ];
        contributionOf[_contributor][_fundingInfo.proposalOwner] = 0;
        token.transfer(_contributor, _amountToTransfer);
    }
}
