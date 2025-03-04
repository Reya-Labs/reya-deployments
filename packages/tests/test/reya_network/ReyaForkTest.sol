pragma solidity >=0.8.19 <0.9.0;

import "forge-std/Test.sol";

import { StorageReyaForkTest } from "../reya_common/StorageReyaForkTest.sol";
import "../reya_common/DataTypes.sol";

import { ICoreProxy } from "../../src/interfaces/ICoreProxy.sol";

contract ReyaForkTest is StorageReyaForkTest {
    constructor() {
        // network
        sec.REYA_RPC = "https://rpc.reya.network";
        sec.MAINNET_RPC = "https://gateway.tenderly.co/public/mainnet";

        // other (external) chain id
        sec.destinationChainId = ethereumChainId;

        // multisigs
        sec.multisig = 0x1Fe50318e5E3165742eDC9c4a15d997bDB935Eb9;

        // Reya contracts
        sec.core = payable(0xA763B6a5E09378434406C003daE6487FbbDc1a80);
        sec.pool = payable(0xB4B77d6180cc14472A9a7BDFF01cc2459368D413);
        sec.perp = payable(0x27E5cb712334e101B3c232eB0Be198baaa595F5F);
        sec.oracleManager = 0xC67316Ed17E0C793041CFE12F674af250a294aab;
        sec.periphery = payable(0xCd2869d1eb1BC8991Bc55de9E9B779e912faF736);
        sec.ordersGateway = payable(0xfc8c96bE87Da63CeCddBf54abFA7B13ee8044739);
        sec.oracleAdaptersProxy = payable(0x32edABC058C1207fE0Ec5F8557643c28E4FF379e);
        sec.exchangePass = 0x76e3f2667aC55d502e26e59C5A6B46e7079217c7;
        sec.accountNft = 0x0354e71e0444d08e0Ce5E49EB91531A1Cac61144;

        // Camelot contracts
        sec.camelotYakRouter = 0x2b59Eb03865D18d8B62a5956BBbFaE352fc1C148;
        sec.camelotSwapPublisher = 0xE32519ca0e751C754c8E1378846B5cd95A1CB66a;

        // Reya tokens
        sec.rusd = 0xa9F32a851B1800742e47725DA54a09A7Ef2556A3;
        sec.usdc = 0x3B860c0b53f2e8bd5264AA7c3451d41263C933F2;
        sec.weth = 0x6B48C2e6A32077ec17e8Ba0d98fFc676dfab1A30;
        sec.wbtc = 0xa6Cf523f856f4a0aaB78848e251C1b042E6406d5;
        sec.usde = 0xAAB18B45467eCe5e47F85CA6d3dc4DF2a350fd42;
        sec.susde = 0x2339D41f410EA761F346a14c184385d15f7266c4;
        sec.deusd = 0x809B99df4DDd6fA90F2CF305E2cDC310C6AD3C2c;
        sec.sdeusd = 0x4D3fEB76ab1C7eF40388Cd7a2066edacE1a2237D;
        sec.rselini = 0xb6A307Bb281BcA13d69792eAF5Db7c2BBe6De248;
        sec.ramber = 0x63FC3F743eE2e70e670864079978a1deB9c18b76;
        sec.srusd = address(0);

        // Elixir tokens on Mainnet (Ethereum)
        sec.elixirSdeusd = 0x5C5b196aBE0d54485975D1Ec29617D42D9198326;

        // Reya modules
        sec.ownerUpgradeModule = 0x70230eE0CcA326A559410DCEd74F2972306D1e1e;

        // Reya variables
        sec.passivePoolId = 1;
        sec.passivePoolAccountId = 2;

        // Reya bots
        sec.coExecutionBot = 0x0d171dFaab3440c0C88F3a07d8F3e9ffE56C609a;
        sec.poolRebalancer = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        sec.rseliniCustodian = 0x75cfe7F41953cDfeA30C9F6A0BceC6BAA3dA71B0;
        sec.rseliniSubscriber = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        sec.rseliniRedeemer = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        sec.ramberCustodian = 0xdd96e677939f0C78e2D671DD37abB44B49710a5A;
        sec.ramberSubscriber = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        sec.ramberRedeemer = 0xf39e89D97B3EEffbF110Dea3110e1DAF74B9C0Ed;
        sec.aeLiquidator1 = 0x89520d105a125CC6165c6685de262c42113Df9c0;

        // node ids for spot prices
        sec.rusdUsdNodeId = 0xee1b130d36fb70e69aafd49dcf1a2d45d85927fb6ffbe7b83751df0190a95857;
        sec.usdcUsdStorkNodeId = 0xc392c001dcf7749e4cdb7967e7ecac04628dea34555b1963bab626b9ef79d63f;

        sec.ethUsdStorkNodeId = 0xf7f69911b541015e987116388896c1b92743e0d07b7fbe4f247b441f132359e7;
        sec.ethUsdcStorkNodeId = 0x5b964bee06e9f94df6484d38dea687e67ec10326208bec16f89dfdb6cd95c6fc;

        sec.usdeUsdStorkNodeId = 0xd9769cc38a8c1db7761cbb398785c85a4db42608b8ff2273b4146ccd73178851;
        sec.usdeUsdcStorkNodeId = 0xa17767ed077b64b1099fe31491143f856b9ebf5249c9fe23dab93b21a1689663;

        sec.susdeUsdStorkNodeId = 0x5176edbcbb7126ba8fe024a930aaa5a88bfd8a5f0de4c823e19f439d5f6c5c59;
        sec.susdeUsdcStorkNodeId = 0x4886cf0e120ecc44a7218921cfdf8f5dc2ff36d70ecc6f2857031e572dad65e7;

        sec.deusdUsdStorkNodeId = 0x8c8bdfa29a872e123ad1d84f4484ba7a66d901ef61b8d28e536e27c754f110a0;
        sec.deusdUsdcStorkNodeId = 0x82bb2b688e2f358bedf3718b141b7d7bbdac7a51d6347b46ee776bc2b444adee;

        sec.sdeusdDeusdStorkNodeId = 0xa772de4b37974a3283055e04cd7eae5fc8bd330b44adb1aee9c1568cb7d37a03;
        sec.sdeusdUsdcStorkNodeId = 0xc938a9d958707db169635f9c5a82dd2bb3d0e635f92a75b4dd177dd514e034f0;

        sec.rseliniUsdcReyaLmNodeId = 0x32cbf6a5839965f0e6439db08f6e9ec0250c2bc6af874f153616ed8d66dd139e;
        sec.ramberUsdcReyaLmNodeId = 0x42daefd962c3b559d6e382fcbc0e89e3fb7d87e836025141066e2f1f02fd5e99;

        sec.srusdUsdcPoolNodeId = 0x00;

        // node ids for mark prices
        sec.ethUsdStorkMarkNodeId = 0xb9c41e6e69999c8e40c3a5646db91377fe753b3e16144822c73ea760809cf766;
        sec.ethUsdcStorkMarkNodeId = 0x40439e329b13b4833aa09aa740bc44550b3c76f5c06bd46adc6e9647866c5709;

        sec.btcUsdStorkMarkNodeId = 0xde139306051d73ac179d72c46ed0cd170073bbabe92a1efcea4d22236caed093;
        sec.btcUsdcStorkMarkNodeId = 0x0e29c9f656c1f2d92fb02d44fa9fcfc10601f19221cd988621560cdd88b3d151;

        sec.solUsdStorkMarkNodeId = 0xfad4f2a6975b49ea023ca26d330982419a35465cbcf0d1e682f85376144aa43f;
        sec.solUsdcStorkMarkNodeId = 0x820a6b1245d59d02b24c182e63493f0713132c94988ad79567171863e7f9075f;

        sec.arbUsdStorkMarkNodeId = 0xfc9c60fdc7d40695170b19f9271cda3ad52a157da3b45e18ccfafef198163187;
        sec.arbUsdcStorkMarkNodeId = 0xae5d0087b162322862cff9b6e23e12741f3622d8ac9ca985c8a4d6d4273318c9;

        sec.opUsdStorkMarkNodeId = 0x15a1eaacb4f12717419b3cbe59a93cfca931906a24c1623ab0c4b50c1cf999d7;
        sec.opUsdcStorkMarkNodeId = 0xb544ba41664d16424513d1bc8c766a2733d506ce8302cec2864cce6a382dee7a;

        sec.avaxUsdStorkMarkNodeId = 0xa4c0b1e4997123278c08e6c6d9c3ca436d64210c50ed91e3720624dfaf571561;
        sec.avaxUsdcStorkMarkNodeId = 0x84abcc151068e87abbdbedbff58cc5370cec0bf2368d3a3d9bde618594527b81;

        sec.mkrUsdStorkMarkNodeId = 0xc753d4b14c94f35f735f1e6e30a62da94002ec46476e72fa535e5d8794aa1dca;
        sec.mkrUsdcStorkMarkNodeId = 0xeba87760f9cb5f50279ee91edc07a7cfeba3e95b3d7340414fd297f7992ba59b;

        sec.linkUsdStorkMarkNodeId = 0x25136e48d9f8d70bd6bd230dded71c7591e1126012ed091ac3cf9c510ab5df60;
        sec.linkUsdcStorkMarkNodeId = 0xcca24f25e88cbcad721d42193404543b68cbdfbe123fc4f2e56decd2a68dee03;

        sec.aaveUsdStorkMarkNodeId = 0x49b99ce5c7b69b53b7b526813c5f108c362bf5747fc980237e56e48a17f86224;
        sec.aaveUsdcStorkMarkNodeId = 0x384da5d8311ec136f6f82b8dfe36574394b1a7245771cbcfdf6aa411267cb96f;

        sec.crvUsdStorkMarkNodeId = 0x2148a5686b179075a292bb965e6d919daa72fefed36320dc4713c7cdd60a6859;
        sec.crvUsdcStorkMarkNodeId = 0xf9084234a98e60f273c02d4ae7016519c4023ea465ccafad88fac94347b0ec35;

        sec.uniUsdStorkMarkNodeId = 0x9dfccb2a42862c7f15df103018135c7dd725bde418de4aac5f240fac54a5a4ff;
        sec.uniUsdcStorkMarkNodeId = 0x71a2b4ab9766edca50373e43e54dcea91b2a43ebfe390c098b2a76ac75da8d64;

        sec.suiUsdStorkMarkNodeId = 0xf008eaaa3e0402509ad4f3b1af50fbfa22fe0e93323494fe7861a67e5159c265;
        sec.suiUsdcStorkMarkNodeId = 0xd57d83e60236d812f95332675d5d7e798e5a929f4d911e23106657cc3acc8134;

        sec.tiaUsdStorkMarkNodeId = 0xe3fb180343cdca5707cacfffff9ace4db609878670c00675fd75c08c61d61bfe;
        sec.tiaUsdcStorkMarkNodeId = 0xdae91df586e27be52fc11de817a577e19a1036ada4c3cfabb21457facd5cd5ec;

        sec.seiUsdStorkMarkNodeId = 0x7d03e204b44462c2ba2664da04758c97941a8f90c98ddf217b71d00a88ba4c8b;
        sec.seiUsdcStorkMarkNodeId = 0x1150ce3e07d736c3f89a938e353a243d5b3779810823b730fcbb0bee5e274b15;

        sec.zroUsdStorkMarkNodeId = 0x6602399812239046b927daa60cb212821193dcc372b6475a632188478639ac42;
        sec.zroUsdcStorkMarkNodeId = 0xb07dd2e530437506816bae10c8141d5033148ff94d44805cbe8fc501f51e6767;

        sec.xrpUsdStorkMarkNodeId = 0x5ebae03e4fd611ef8093edb13ef47db09ab5b809b5420f032b7997b52ed3b72b;
        sec.xrpUsdcStorkMarkNodeId = 0x7d2cb40ff0c73da1c2cfd83d1f41715f95cf992d86bee60f14a045fe79c0462b;

        sec.wifUsdStorkMarkNodeId = 0x922f80ca37a71468baa1659e4115e3f90ff2d64de604be51481e428aa3ee46a1;
        sec.wifUsdcStorkMarkNodeId = 0xa3ccfcee43c19cec007b006a66d1b366d21d099407a37d40af3c4f6856ee91b0;

        sec.pepe1kUsdStorkMarkNodeId = 0x4a26454f03accc21ea55b84af70ae6e341f9db157f1640d60c95d3386f4af971;
        sec.pepe1kUsdcStorkMarkNodeId = 0xf9e4583c01139e4ac5b097da69a188c34a180f1dd34ce05d01cc740569492604;

        sec.popcatUsdStorkMarkNodeId = 0x74d1cab0aaff7789f646c2550821dd5f69ea7c7f1a34156030536b8feb157603;
        sec.popcatUsdcStorkMarkNodeId = 0x877f87f0e83878498c00ce65d884d59cc64cf428b2c6282c60f5b3be8ef43846;

        sec.dogeUsdStorkMarkNodeId = 0x62af2e85b91624b749eac4dc6fb0097068620e1f863a8e4e9d8790b99b989349;
        sec.dogeUsdcStorkMarkNodeId = 0x82fbad667884fb2e7696771e28b21b9becca3b00c6015708dd061eadbad527d2;

        sec.kshibUsdStorkMarkNodeId = 0xc5233c69c0c0776f586556eb59f7e8585160a9d2ca0c7c890dea06914d981f15;
        sec.kshibUsdcStorkMarkNodeId = 0xdcd17b3db84c05f0579f84ff7e9390c4e27b02d9aa9be9ba3c02e1c08ac9345e;

        sec.kbonkUsdStorkMarkNodeId = 0x4d22904b2194dcda3678655c03e7864bc139d1e72c8fe0d97d5cbbd366878e6d;
        sec.kbonkUsdcStorkMarkNodeId = 0xb7082b990c3aaf729ee79d955dda71b9477acc2886f69ab83ff5c03ee8515c31;

        sec.aptUsdStorkMarkNodeId = 0x721791481417b236a89638a46e382cb92537af627b03d6889479d97a5a19d6d5;
        sec.aptUsdcStorkMarkNodeId = 0xff18e68f091641f547f4a83233d46f5f281aa75dcf7f86fe3c97b3c28ec959f0;

        sec.bnbUsdStorkMarkNodeId = 0x9b33ca1b45555a913d05802d7049feb065c764e4bdb4ceaf1c9b99cf79a26d03;
        sec.bnbUsdcStorkMarkNodeId = 0x3e9c633aca82b237b167f5d8cc1e19d7b171f9dc786537e45b632d82d451ca6b;

        sec.jtoUsdStorkMarkNodeId = 0x32a54d4f182c9c66fe9eb41ae9183ee32a528e7a23017a03d1c0eea7960a8258;
        sec.jtoUsdcStorkMarkNodeId = 0xc345cd85d636fb32f3faf336bef0d466d11a070e8fa84b6aa0a9b9ee4ff7aa0a;

        sec.adaUsdStorkMarkNodeId = 0xf7d389c2344e4d30781f210071c3c13790aad268b969ab39fb86456cc979ecf0;
        sec.adaUsdcStorkMarkNodeId = 0xf0278ee390acbd3027eb50fbee07457257b55ab73083df390cc4768be43fc94d;

        sec.ldoUsdStorkMarkNodeId = 0xc74d6ea960ef9615a436a880127dad288a043af043bcbcae6188736563658537;
        sec.ldoUsdcStorkMarkNodeId = 0x8ee41dbcf20673253d0f3a6d30acb60294d2973125b65ed79e1467a62ec035df;

        sec.polUsdStorkMarkNodeId = 0x43087a65b16a825d10912d4ef0a56eaac2242dfb3158cf0321f3b35fc0c7f61a;
        sec.polUsdcStorkMarkNodeId = 0xfc1124aeb7b1a71720e58f1b87e99b733d0f177cf28fcf3ed1580aa6c1b13c90;

        sec.nearUsdStorkMarkNodeId = 0x1cbed930dc4d277758237164b2f9c625b5d733bdd16b77268111b16b7b426fea;
        sec.nearUsdcStorkMarkNodeId = 0xdbd8543af7cc96fac35926c15ef5f13f89bc873721211493e112d4bc4f275cd2;

        sec.ftmUsdStorkNodeId = 0x121a33532e703bfaa003a784b1f69bea1737c686136b15ab4eda8ec6a9142e1a;
        sec.ftmUsdcStorkNodeId = 0xdadaa29fe1e6f8959640a9222b3a7c6a0099bd778da90da5167d986f75b69a59;

        sec.enaUsdStorkMarkNodeId = 0x4d06d4eaa2f04e517035af06b005157b38f2999e0e46510ef5d744d151111703;
        sec.enaUsdcStorkMarkNodeId = 0xe19227f2d63cb74d087e1679dce6a66d9ae137d83ded1d2d294c41fdd38f5912;

        sec.eigenUsdStorkMarkNodeId = 0xaa8008f4443d8eb90fe63a6a3d90089d97195640eba8b60981be1d506221e86b;
        sec.eigenUsdcStorkMarkNodeId = 0x345d048d424bd2c4b3559601b73afd8e837f65196bd51b989781ae55e76f8c23;

        sec.pendleUsdStorkMarkNodeId = 0xd37aa03141faf5205c7481cb853b7ef950483f8bdedfdb5a273a150427a3aef6;
        sec.pendleUsdcStorkMarkNodeId = 0x698c2bb8d74cf2c350cc8c1724bf14650cd7a7164d660e30da08c1cbd638dfb0;

        sec.goatUsdStorkMarkNodeId = 0x7c9bba0499998bfc2c1f2a21eb5b8ee7dc5a865eaf4e6dff36fe6e987ffa279e;
        sec.goatUsdcStorkMarkNodeId = 0xad4473e51e15cde6fabacd8992f87f363d0a56b67260d55f20f42608b8c0e061;

        sec.grassUsdStorkMarkNodeId = 0x79961b55ec036ab08cd00fc633f2e77d60cb67238e7694eaa16308b564341661;
        sec.grassUsdcStorkMarkNodeId = 0x3b63f7ee280b405050690d30fd3efeaa6ecfa6ba4b09b2f3ac7bb586a348a34b;

        sec.kneiroUsdStorkMarkNodeId = 0x33a1175eff91f9d43b12a871a08186c5aa856506e9342b7cb8e51a948809076e;
        sec.kneiroUsdcStorkMarkNodeId = 0x20c07861bda3900f5ef4b9bdf206f2bc884dc592ef99fe3d75b604d2036c26d3;

        sec.dotUsdStorkMarkNodeId = 0x489685d39110a930c5fa215e74e85b15151cad2d6da337b09ffead44dd5b7bba;
        sec.dotUsdcStorkMarkNodeId = 0x5099b862da19a97b29ea4ff3f243b52b1ea35f705a76bc4f5bd54e25006d2b12;

        sec.ltcUsdStorkMarkNodeId = 0x611972e93ef84a3f07ad07ca26a2478d1c1bca55dc2543e3a7c285a0bcc51d8b;
        sec.ltcUsdcStorkMarkNodeId = 0x490da6b2048301e76697bf5b0d80d21ad8e2c2347e99fc1fb047b43288c547b3;

        sec.pythUsdStorkMarkNodeId = 0x918270943e6a3b5e039d4bf00b36e05db55fcde5a4621d1b9a5b3036bb0e9bb9;
        sec.pythUsdcStorkMarkNodeId = 0x73f9cb8b7623659f3a9582e4d1a259e77344dc67d2142b2730de0e083c2e6f90;

        sec.jupUsdStorkMarkNodeId = 0xfadcd2361bc98edbf20b9b1f78f22f5fb1df037dfa1347e0d58d018c0682915a;
        sec.jupUsdcStorkMarkNodeId = 0x1f434db51fab16e77a195d9bdc8846542d08e88025d4e7871b07046387bae466;

        sec.penguUsdStorkMarkNodeId = 0xafb171b1f46d22bf1d53c343d923a371cf57effc18a23d79d09a4a2e5279f407;
        sec.penguUsdcStorkMarkNodeId = 0x6321236542711f17aa8ce3c055f7d2ccdb4b755c0eff0a1a31688fa1deaceaca;

        sec.trumpUsdStorkMarkNodeId = 0x6095728f805c90386c21a61c37151752a0e8d2a4866e0fe6b4950d505b4a8538;
        sec.trumpUsdcStorkMarkNodeId = 0x651c42a2429609c6a02c1d7e99330f3c7ac8b81a31720d0a5c3937ac32261773;

        sec.hypeUsdStorkMarkNodeId = 0xbaadee4b6755421f71b1eaa62ea45b59bba58fb766539b739c4711e6359c8b67;
        sec.hypeUsdcStorkMarkNodeId = 0xc576e5872e616b1b6d5784449f32e5af0df4ad1a403071af37baba053a5b3479;

        sec.virtualUsdStorkMarkNodeId = 0x0b3254583f14da262359768068595971bc4a326acbac8f05b3bcec53f7fcc603;
        sec.virtualUsdcStorkMarkNodeId = 0x978f9a53112646ebb1344bed5eeb363eadb1fb907864832da126aa6dfca349a6;

        sec.ai16zUsdStorkMarkNodeId = 0x8e98645bff30736409a1b816987bb7929d267bb5416bec04558f6fb724516244;
        sec.ai16zUsdcStorkMarkNodeId = 0xdec3427a0f3773074ae2cad7f77cf9bf54b96c8ed8a6c595f2a852840171eec0;

        sec.aixbtUsdStorkMarkNodeId = 0x63d2a9f3409e87400c48928f9ab753ae007bfdaec861dcc89a34db935afb993b;
        sec.aixbtUsdcStorkMarkNodeId = 0xd270b9614f0e722b0941c8e309a8cc7e41391671c2e24702f50b47952eb27f78;

        sec.sonicUsdStorkMarkNodeId = 0x5f0bfc7f1a7f24893e97be81242fc6ea9d24a1145b6fe26190ff79032f844cdf;
        sec.sonicUsdcStorkMarkNodeId = 0xba08544b817c8840bbd65560e0e856fc2de0f14de2c6fd0c0be68b5612bbb579;

        sec.fartcoinUsdStorkMarkNodeId = 0x4711aa5e3bfbea19e597d3f6be67bb92dbbc2902ea485021eeb7752f35198730;
        sec.fartcoinUsdcStorkMarkNodeId = 0x99117cf6e8a768582ea5df10a2152e1613bb8eb4fbb5bf777cb8d9aa7c57d89f;

        sec.griffainUsdStorkMarkNodeId = 0xe4469920fd7f3a76db1f84237a70fe131dad1f795a177d0cf417bcc00f6a1eee;
        sec.griffainUsdcStorkMarkNodeId = 0x20136f006a8e47c9f43e8d3362e22c2bc28396e0980a8870049d0d37778a03bd;

        sec.wldUsdStorkMarkNodeId = 0xbc4a40bc3f3bc739736446801b49b16017419d32c51be2e9ae9b71346648d538;
        sec.wldUsdcStorkMarkNodeId = 0xca95fec2fb2ac6c2c99dbe209620a67973608ba5e1adc1a8fcbe7f339b576081;

        sec.atomUsdStorkMarkNodeId = 0x27612d1d82b62dc14f0f65c27a800aba0df4f4497fee9f97e7ccf7e65b45b4bf;
        sec.atomUsdcStorkMarkNodeId = 0x743cf34170848af6d3e284cd3493821340fd9f57a2267015712880a0c3836519;

        sec.apeUsdStorkMarkNodeId = 0xb4bf4e85e81a0975ef9b54d1baa3e939c5496776188d36abe0ff95049f551a8c;
        sec.apeUsdcStorkMarkNodeId = 0x56a34877fa74ad093273a29f1a861845473580739b6a3789dce0cacb31f7c75e;

        sec.tonUsdStorkMarkNodeId = 0x81c6008219c52b16c7bba0934f3d3c6509a17a6c68502c0401dfec882f257f53;
        sec.tonUsdcStorkMarkNodeId = 0x0f33deaa70cde4fe4f722678305dd5f65b2d27565cfccadc867e894d620480c0;

        sec.ondoUsdStorkMarkNodeId = 0x6d5f6de977b5905e6b8411cf51648bcd8c23481218b947451aad31a29825d1e6;
        sec.ondoUsdcStorkMarkNodeId = 0xfe7baf562adeaef4ebfb04a6ed1ee599f7a4a939afb87adfc7d8295556ec5253;

        sec.trxUsdStorkMarkNodeId = 0xf9b6b7be713c9dafef906de707436d99fb4629039fafa9f9303d57814e7809fb;
        sec.trxUsdcStorkMarkNodeId = 0x2e58649840517ed71c07c34bd2d362117686862a2038915d696698780c373fe6;

        sec.injUsdStorkMarkNodeId = 0x5c5168c58833f894a877a11290b4f30611761fe16078fbf8506e40a8ce3a9fed;
        sec.injUsdcStorkMarkNodeId = 0x0ffac0939debabb4b95ac3690fb11f18ec895ef3714348f6e6fa31fd2384870e;

        sec.moveUsdStorkMarkNodeId = 0xc8a0c66533e534ba674eeb88be2419ed729c1f7486040e040121fea6c4776207;
        sec.moveUsdcStorkMarkNodeId = 0x41eedd0c7e99062ddc6b2236d832421f93bedb1a1c0a199d60d36a910505835a;

        sec.beraUsdStorkMarkNodeId = 0x4062c06c9e7bbacfaaa64122dac852bf681e060ba1f270d7ae6d37b1fd9e8e83;
        sec.beraUsdcStorkMarkNodeId = 0x5e066410873633e2144d5d84f6103598c1fd58d8481c4b3f8ee27278613a100c;

        sec.layerUsdStorkMarkNodeId = 0x2f73df82f135e40f91791306aed8e1ede704c034409a72aa92271c97ac2468be;
        sec.layerUsdcStorkMarkNodeId = 0x7e8c35128fcb04b662843e6db2359f97cca981fbe54f1f8a4b660d4b4fa93f6e;

        sec.taoUsdStorkMarkNodeId = 0x311f98e0cbea124c7add927d760065acb846191e789f5adca7f336276681591f;
        sec.taoUsdcStorkMarkNodeId = 0x20ea080fd3e412b5866026e74975a51278ec526ddef595d29d332086c617fac0;

        sec.ipUsdMarkNodeIdStork = 0x31a9c7ff27a8fe628657d3df8f65a095f07001a000cc24b144a31c41404ac214;
        sec.ipUsdcMarkNodeIdStork = 0xc6e576793b02473ea40dab35b5f23bbfe4dc56159940f5f6139f0e4e3822f8b3;

        sec.meUsdMarkNodeIdStork = 0xb63ceab97734e1c0e1753d7159b2b73f4fb9c575dbd9e679edc118b6249316a8;
        sec.meUsdcMarkNodeIdStork = 0x005ba8cf801945fe393812fff754d399e4718538bd78f83d490201a5eef466eb;

        // Socket variables
        dec.socketController[sec.usdc] = 0x1d43076909Ca139BFaC4EbB7194518bE3638fc76;
        dec.socketExecutionHelper[sec.usdc] = 0x9ca48cAF8AD2B081a0b633d6FCD803076F719fEa;
        dec.socketConnector[sec.usdc][ethereumChainId] = 0x807B2e8724cDf346c87EEFF4E309bbFCb8681eC1;
        dec.socketConnector[sec.usdc][arbitrumChainId] = 0x3F19417872BC9F5037Bc0D40cE7389D05Cf847Ad;
        dec.socketConnector[sec.usdc][optimismChainId] = 0x321C2Bd69819a43C340b55db40F7c8Eb3334cDe0;
        dec.socketConnector[sec.usdc][polygonChainId] = 0x54CAA0946dA179425e1abB169C020004284d64D3;
        dec.socketConnector[sec.usdc][baseChainId] = 0x3694Ab37011764fA64A648C2d5d6aC0E9cD5F98e;

        dec.socketController[sec.weth] = 0xF0E49Dafc687b5ccc8B31b67d97B5985D1cAC4CB;
        dec.socketExecutionHelper[sec.weth] = 0xBE35E24dde70aFc6e07DF7e7BD8Ce723e1712771;
        dec.socketConnector[sec.weth][ethereumChainId] = 0x7dE4937420935c7C8767b06eCd7F7dC54e2D7C9b;
        dec.socketConnector[sec.weth][arbitrumChainId] = 0xd95c5254Df051f378696100a7D7f29505e5cF5c9;
        dec.socketConnector[sec.weth][optimismChainId] = 0xDee306Cf6C908d5F4f2c4A92d6Dc19035fE552EC;
        dec.socketConnector[sec.weth][polygonChainId] = 0x530654F6e96198bC269074156b321d8B91d10366;
        dec.socketConnector[sec.weth][baseChainId] = 0x2b3A8ABa1E055e879594cB2767259e80441E0497;

        dec.socketController[sec.wbtc] = 0xBF839f4dfF854F7a363A033D57ec872dC8556693;
        dec.socketExecutionHelper[sec.wbtc] = 0xd947Dd2f18366F3FD1f2a707d3CA58F762D60519;
        dec.socketConnector[sec.wbtc][ethereumChainId] = 0xD71629697B71E2Df26B4194f43F6eaed3B367ac0;
        dec.socketConnector[sec.wbtc][arbitrumChainId] = 0x42229a5DDC5E32149311265F6F4BC016EaB778FC;
        dec.socketConnector[sec.wbtc][optimismChainId] = 0xA6BFB87A0db4693a4145df4F627c8FEe30aC7eDF;
        dec.socketConnector[sec.wbtc][polygonChainId] = 0xA30e479EbfD576EDd69afB636d16926a05214149;

        dec.socketController[sec.usde] = 0xF5D4ea96d2efbdAB9C63fA85d2c45e8B75dF640c;
        dec.socketExecutionHelper[sec.usde] = 0xC53D91C6D595b4259fa5649d77e1e31E648202A3;
        dec.socketConnector[sec.usde][ethereumChainId] = 0xf004c4c51b6c026247B5910706Ee78134299eaBD;

        dec.socketController[sec.susde] = 0x3379f120917fb67728d6Db6065d9fDBBd1507A7B;
        dec.socketExecutionHelper[sec.susde] = 0x9e51CDbD0dC54E314B6b17C69ED34a98B8259A16;
        dec.socketConnector[sec.susde][ethereumChainId] = 0x888f5426Bf4E387770A225d0097f0716aF98e7b5;
        dec.socketConnector[sec.susde][arbitrumChainId] = 0x4f471ff392733b722992F012e40728e36c5e9848;
        dec.socketConnector[sec.susde][optimismChainId] = 0x79C06E5BD8e7a4dc151D7591eba71C2a5D49e2B6;
        dec.socketConnector[sec.susde][baseChainId] = 0xE71b58F3324d06786cA70b3c9695df23EEaaF630;

        dec.socketController[sec.deusd] = 0x322A8EA44716586b6BB31456055e61B28da4f1C1;
        dec.socketExecutionHelper[sec.deusd] = 0xEB7F89394B325a021259939DA5Ba5EE83984b7F5;
        dec.socketConnector[sec.deusd][ethereumChainId] = 0x65ce0D9c5bbF43ee7A6011B3D077DD2FeA6b2726;

        dec.socketController[sec.sdeusd] = 0xCDb4A30CEBbf9d8C14e4e96fDe6EA7E40c6f3f5B;
        dec.socketExecutionHelper[sec.sdeusd] = 0x70c46c24f9f923F44278C3B5451986C175c39F73;
        dec.socketConnector[sec.sdeusd][ethereumChainId] = 0x2dc464B4f5Fd55ea19f0bdF71A8dc3584eeb64d7;

        // create fork
        try vm.activeFork() { }
        catch {
            vm.createSelectFork(sec.REYA_RPC);
        }

        // setup
        // (*) allow anyone to publish match orders
        vm.prank(sec.multisig);
        ICoreProxy(sec.core).setFeatureFlagAllowAll(keccak256(bytes("matchOrderPublisher")), true);
    }
}
