// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19 <0.9.0;

import { BaseEthereumForkTest } from "../BaseEthereumForkTest.sol";
import { BaseReyaOFTForkCheck } from "../../reya_common/tge/ReyaOFT.fork.c.sol";

contract ReyaOFTForkCheck is BaseReyaOFTForkCheck, BaseEthereumForkTest {
    // Note: _initOFTCheck must be called by the derived contract after sec is initialized
}
