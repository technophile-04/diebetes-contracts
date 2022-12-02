//SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "base64-sol/base64.sol";
import {IConnext} from "@connext/nxtp-contracts/contracts/core/connext/interfaces/IConnext.sol";

contract NFT is ERC721Enumerable {
    uint32 public constant DOMAIN_ID = 1735353714; //swap domain id

    IConnext public immutable connext;

    using Strings for uint256;
    using Strings for uint160;
    using Strings for uint16;

    /* ========== STATE VARIABLES ========== */

    /* == constants and immutables == */

    /* == states == */
    uint16 private _tokenIds;

    /* ========== Functions ========== */
    constructor(IConnext _connext) ERC721("NFT Certificate", "NFT_CERTI") {
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

    function tokenURI(
        uint256 id
    ) public view override returns (string memory json) {
        require(_exists(id), "!exist");

        EthManProperties memory properites = getPropertiesById(uint16(id));

        if (isHappy[uint16(id)]) {
            return
                string.concat(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string.concat(
                                '{"name":"',
                                string.concat("ETH Man #", id.toString()),
                                '","description":"',
                                string.concat(
                                    "This ETH Man was born with a Happy face! with face color ",
                                    properites.faceColor
                                ),
                                '","attributes":[{"trait_type":"Eyes Color","value":"',
                                properites.eyesColor,
                                '"},{"trait_type":"Hands Color","value":"',
                                properites.handsColor,
                                '"},{"trait_type":"Legs Color","value":"',
                                properites.legsColor,
                                '"},{"trait_type":"Happy","value":"Yes',
                                '"}],"owner":"',
                                (uint160(ownerOf(id))).toHexString(20),
                                '","image": "',
                                "data:image/svg+xml;base64,",
                                Base64.encode(
                                    bytes(generateSVGofTokenById(uint16(id)))
                                ),
                                '"}'
                            )
                        )
                    )
                );
        }
    }

    function generateSVGofTokenById(
        uint16 id
    ) internal view returns (string memory) {
        string memory svg = string.concat(
            "<svg xmlns='http://www.w3.org/2000/svg'  width='200' height='200' viewBox='-100 -100 200 200'>",
            renderTokenById(id),
            "</svg>"
        );
        return svg;
    }

    function renderTokenById(uint16 id) public view returns (string memory) {
        string memory render;

        if (happy) {
            render = string.concat(
                '<svg width="250" height="150" style="border:1px solid red; background-color:',
                "gold",
                '"/>',
                '<text x="20" y="25" fill="purple">Title : This is proposal</text>'',
                '<text x="20" y="55" fill="purple">Benefits : </text>',
                '<text x="20" y="75" fill="purple">1) 60% off on medicines </text><text x="20" y="95" fill="purple">2) 80% off on medicines </text>',
                "</svg>"
            );
        }

        return render;
    }

    function getPropertiesById(
        uint16 id
    ) public view returns (EthManProperties memory properites) {
        // 7 is length of HUEs array
        uint256 pseudoRandomNumber = tokenIdToRandomNumber[id];
        uint8 randomFaceIndex = uint8(pseudoRandomNumber % 7);

        properites.faceColor = string.concat(
            "hsl(",
            tokenIdToHue[id][randomFaceIndex].toString(),
            ",90%",
            ",70%)"
        );

        uint8 eyesIndex = uint8((pseudoRandomNumber + 1) % 7);
        properites.eyesColor = string.concat(
            "hsl(",
            tokenIdToHue[id][eyesIndex].toString(),
            ",90%",
            ",60%)"
        );

        // 9 means not assigned
        uint8 smileIndex = 9;

        for (uint8 i = 0; i < 7; i++) {
            smileIndex = uint8((pseudoRandomNumber + i + 2) % 7);
            if (smileIndex != randomFaceIndex) {
                properites.mouthColor = string.concat(
                    "hsl(",
                    tokenIdToHue[id][i].toString(),
                    ",90%",
                    ",60%)"
                );
                break;
            } else if (i == 6) {
                smileIndex = uint8((pseudoRandomNumber + 9) % 7);
                properites.mouthColor = string.concat(
                    "hsl(",
                    tokenIdToHue[id][smileIndex].toString(),
                    ",90%",
                    ",60%)"
                );
            }
        }

        properites.legsColor = string.concat(
            "hsl(",
            tokenIdToHue[id][6].toString(),
            ",90%",
            ",70%)"
        );

        uint8 handColorIndex = uint8((pseudoRandomNumber + 4) % 7);

        if (handColorIndex != 6) {
            properites.handsColor = string.concat(
                "hsl(",
                tokenIdToHue[id][handColorIndex].toString(),
                ",90%",
                ",70%)"
            );
        } else {
            handColorIndex = uint8((pseudoRandomNumber + 5) % 7);
            properites.handsColor = string.concat(
                "hsl(",
                tokenIdToHue[id][handColorIndex].toString(),
                ",90%",
                ",70%)"
            );
        }

        return properites;
    }
}
