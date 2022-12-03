// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {Base64} from "./Base64.sol";

contract NFC is ERC721Enumerable {
    uint32 public constant DOMAIN_ID = 9991;

    string[3] public colors = ["#CD7F32", "#E5E4E2", "#FFD700"];
    mapping(uint256 => string) idToColor;

    IConnext public immutable connext;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(IConnext _connext) ERC721("NFT Certifiacte", "NFC") {
        connext = _connext;
    }

    function xReceive(
        bytes32 _transferId,
        uint256 _amount,
        address _asset,
        address _originSender,
        uint32 _origin,
        bytes memory _callData
    ) external returns (bytes memory) {
        // avoiding compiler warnings
        _transferId;
        _amount;
        _asset;
        _originSender;
        _origin;
        // Unpack the _callData
        (address _contributor, uint256 _contributedAmount) = abi.decode(
            _callData,
            (address, uint256)
        );
        _tokenIds.increment();
 
        {
            uint256 _id = _tokenIds.current();
            if (_contributedAmount <= 0.05 ether) {
                idToColor[_id] = "#CD7F32";
            } else if (_contributedAmount <= 0.1 ether) {
                idToColor[_id] = "#E5E4E2";
            } else {
                idToColor[_id] = "#FFD700";
            }

            _mint(_contributor, _id);
        }
    }

    function withhdrawFunds(
        uint256 _id,
        address _target,
        uint256 _proposalId
    ) external {
        _burn(_id);
        bytes memory _callData = abi.encode(msg.sender, _proposalId);

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

    function totalMint() public view returns (uint256) {
        return _tokenIds.current();
    }

    function tokenURI(
        uint256 id
    ) public view override returns (string memory json) {
        require(_exists(id), "!exist");

        return generateSVG(id);
    }

    function generateSVG(uint256 _id) private view returns (string memory) {
        string memory strId = Strings.toString(_id);
        string memory certificateBG = idToColor[_id];

        string memory finalSvg = string(
            abi.encodePacked(
                '<svg width="250" height="150" style="border:1px solid red; background-color: "',
                certificateBG,
                '">',
                '<text x="20" y="25" fill="purple"> Title :',
                "This is proposal",
                "</text>",
                '<text x="20" y="55" fill="purple"> Benefits : </text>',
                '<text x="20" y="75" fill="purple">1)',
                "60% off on medicines",
                "</text>",
                '<text x="20" y="95" fill="purple">2)',
                "Life time free home delivery",
                "</text>",
                "</svg>"
            )
        );

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{ "name": "NFC #',
                        strId,
                        '", "description": "NFC is a initicative for wellness and goodness towords the new world.", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(finalSvg)),
                        '"}'
                    )
                )
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", json));
    }
}
