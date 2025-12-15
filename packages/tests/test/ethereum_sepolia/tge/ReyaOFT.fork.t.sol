// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { EthereumForkTest } from "../EthereumForkTest.sol";
import { ReyaOFTForkCheck } from "../../ethereum_common/tge/ReyaOFT.fork.c.sol";
import { IReyaOFT } from "../../../src/interfaces/IReyaOFT.sol";
import { ILayerZeroEndpointV2 } from "../../../src/interfaces/ILayerZeroEndpointV2.sol";
import { IProxyAdmin } from "../../../src/interfaces/IProxyAdmin.sol";
import { ITransparentUpgradeableProxy } from "../../../src/interfaces/ITransparentUpgradeableProxy.sol";

contract ReyaOFTForkTest is EthereumForkTest, ReyaOFTForkCheck {
    constructor() {
        // EthereumForkTest constructor runs first and initializes sec
        // Now we can initialize the OFT check with the values from sec
        _initOFTCheck(sec.reya, sec.foundationMultisig);
    }

    function test_ReyaOFT_ContractStorage() public view {
        // Debug test to verify the contract exists in the fork
        uint256 codeSize;
        address reyaToken = reya;
        assembly {
            codeSize := extcodesize(reyaToken)
        }
        require(codeSize > 0, "ReyaOFT contract does not exist at expected address");
        
        // Check if it's a proxy and verify implementation
        // TransparentUpgradeableProxy stores implementation at slot:
        // bytes32(uint256(keccak256('eip1967.proxy.implementation')) - 1)
        bytes32 implementationSlot = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
        bytes32 implementationBytes = vm.load(reyaToken, implementationSlot);
        address implementation = address(uint160(uint256(implementationBytes)));
        
        // Check implementation has code
        uint256 implCodeSize;
        assembly {
            implCodeSize := extcodesize(implementation)
        }
        
        require(implementation != address(0), "Implementation address is zero");
        require(implCodeSize > 0, "Implementation contract has no code");

        // Check lzEndpoint is set correctly
        IReyaOFT token = IReyaOFT(reyaToken);
        address lzEndpoint = token.endpoint();
        require(lzEndpoint == 0x6EDCE65403992e310A62460808c4b910D972f10f, "lzEndpoint does not match expected address");

        // Check lzEndpoint delegate is set to foundationMultisig
        address delegate = ILayerZeroEndpointV2(lzEndpoint).delegates(reyaToken);
        require(delegate == foundationMultisig, "lzEndpoint delegate is not foundationMultisig");

        // Check Proxy Admin owner
        address proxyAdminOwner = IProxyAdmin(ITransparentUpgradeableProxy(reya).getAdmin()).owner();
        require(proxyAdminOwner == foundationMultisig, "Proxy Admin owner is not foundationMultisig");
    }

    function test_ReyaOFT_Permissions() public {
        address[] memory permissioned = new address[](4);
        permissioned[0] = 0x140d001689979ee77C2FB4c8d4B5F3E209135776;
        permissioned[1] = 0xA73d7b822Bfad43500a26aC38956dfEaBD3E066d;
        permissioned[2] = 0xf94e5Cdf41247E268d4847C30A0DC2893B33e85d;
        permissioned[3] = 0xC68ed61DCe11Ba16586bCa350139cFDFc65D1Ca6;
        check_ReyaOFT_Permissions(permissioned);
    }

    function test_ReyaOFT_BlacklistedCannotTransfer() public {
        check_ReyaOFT_BlacklistedCannotTransfer(foundationMultisig);
    }

    function test_ReyaOFT_OwnerCanMint() public {
        check_ReyaOFT_OwnerCanMint();
    }

    function testFuzz_ReyaOFT_NonOwnerCannotMint(address attacker) public {
        vm.assume(attacker != foundationMultisig);
        checkFuzz_ReyaOFT_NonOwnerCannotMint(attacker);
    }

    function test_ReyaOFT_EndpointIsSet() public view {
        check_ReyaOFT_EndpointIsSet(0x6EDCE65403992e310A62460808c4b910D972f10f);
    }

    function test_ReyaOFT_EndpointDelegatedToOwner() public view {
        check_ReyaOFT_EndpointDelegatedToOwner();
    }

    function test_ReyaOFT_PeersConfigured() public view {
        check_ReyaOFT_PeersConfigured(40319); // eid of eth mainnet
    }

    function test_ReyaOFT_SendWorks() public {
        check_ReyaOFT_SendWorks(40319);
    }

    function test_ReyaOFT_SendRespectsBlacklist() public {
        check_ReyaOFT_SendRespectsBlacklist(40319);
    }

    function test_ReyaOFT_SendRespectsPause() public {
        check_ReyaOFT_SendRespectsPause(40319);
    }

    function test_ReyaOFT_OnlyEndpointCanCallLzReceive() public {
        check_ReyaOFT_OnlyEndpointCanCallLzReceive();
    }

    function test_ReyaOFT_LzReceiveMintsTokens() public {
        check_ReyaOFT_LzReceiveMintsTokens(40319);
    }

    function test_ReyaOFT_LzReceiveRespectsPause() public {
        check_ReyaOFT_LzReceiveRespectsPause(40319);
    }

    function test_ReyaOFT_NormalTransfer() public {
        check_ReyaOFT_NormalTransfer();
    }
}
