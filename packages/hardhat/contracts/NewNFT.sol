// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";
import {Base64} from "./Base64.sol";

contract NFA is ERC721URIStorage, Ownable, ReentrancyGuard {
    uint32 public constant DOMAIN_ID = 1735353714; //swap domain id

    string[3] public constant colors = ["#CD7F32", "#E5E4E2", "#FFD700"];

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
        // Unpack the _callData
        address _contributor = abi.decode(_callData, (address));
        _tokenIds = _tokenIds + 1;
        _mint(msg.sender, _tokenIds);
        // we will pass amount to `generateSVG`
        _setTokenURI(_id, generateSVG(_to, _id));
        // _setTokenURI(_id, generateSVG(_to, _id, amount));
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

    function generateSVG(string memory _to, uint256 _id)
        private
        view
        returns (string memory)
    {
        string memory strId = Strings.toString(_id);
        string[12] memory value;

        value[
            0
        ] = '<svg width="250" height="150" style="border:1px solid red; background-color: gold">';
        value[1] = '<text x="20" y="25" fill="purple"> Title :';
        value[2] = "This is proposal";
        value[3] = "</text>";
        value[4] = '<text x="20" y="55" fill="purple"> Benefits : </text>';
        value[6] = '<text x="20" y="75" fill="purple">1)';
        value[7] = "60% off on medicines";
        value[8] = "</text>";
        value[9] = '<text x="20" y="95" fill="purple">2)';
        value[10] = "Life time free home delivery";
        value[11] = "</text>";

        string memory finalSvg = string(
            abi.encodePacked(
                value[0],
                value[1],
                value[2],
                value[3],
                value[4],
                value[5],
                value[6],
                value[7],
                value[8],
                value[9],
                value[10],
                value[11],
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

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        return finalTokenUri;
    }
}
