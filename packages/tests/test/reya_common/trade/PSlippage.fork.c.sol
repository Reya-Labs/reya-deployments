pragma solidity >=0.8.19 <0.9.0;

import { BaseReyaForkTest } from "../BaseReyaForkTest.sol";

import { ICoreProxy, MarginInfo } from "../../../src/interfaces/ICoreProxy.sol";

import { IPassivePerpProxy, MarketConfigurationData } from "../../../src/interfaces/IPassivePerpProxy.sol";

import { IPeripheryProxy, DepositNewMAInputs } from "../../../src/interfaces/IPeripheryProxy.sol";

import { sd, SD59x18, UNIT as UNIT_sd } from "@prb/math/SD59x18.sol";
import { ud, UD60x18 } from "@prb/math/UD60x18.sol";

struct LocalState {
    address user;
    MarketConfigurationData marketConfig;
    SD59x18 poolBase;
    uint256 passivePoolImMultiplier;
    int64[][] marketRiskMatrix;
    SD59x18 pSlippage;
    int64 a;
    SD59x18[] sLong;
    SD59x18[] sShort;
    SD59x18[] s;
    SD59x18[] sPrime;
    mapping(int64 a => mapping(uint256 depth => SD59x18[] sPrime)) sPrimeLong;
    mapping(int64 a => mapping(uint256 depth => SD59x18[] sPrime)) sPrimeShort;
}

contract PSlippageForkCheck is BaseReyaForkTest {
    LocalState private st;

    constructor() {
        st.sLong = new SD59x18[](10);
        st.sLong[1] = sd(0.01e18);
        st.sLong[2] = sd(0.02e18);
        st.sLong[3] = sd(0.03e18);
        st.sLong[4] = sd(0.04e18);
        st.sLong[5] = sd(0.05e18);
        st.sLong[6] = sd(0.06e18);
        st.sLong[7] = sd(0.07e18);
        st.sLong[8] = sd(0.08e18);
        st.sLong[9] = sd(0.09e18);

        st.sShort = new SD59x18[](10);
        st.sShort[1] = sd(-0.01e18);
        st.sShort[2] = sd(-0.02e18);
        st.sShort[3] = sd(-0.03e18);
        st.sShort[4] = sd(-0.04e18);
        st.sShort[5] = sd(-0.05e18);
        st.sShort[6] = sd(-0.06e18);
        st.sShort[7] = sd(-0.07e18);
        st.sShort[8] = sd(-0.08e18);
        st.sShort[9] = sd(-0.09e18);

        st.sPrimeLong[0.00037e18][23e18] = new SD59x18[](10);
        st.sPrimeLong[0.00037e18][23e18][1] = sd(0.01e18);
        st.sPrimeLong[0.00037e18][23e18][2] = sd(0.01973e18);
        st.sPrimeLong[0.00037e18][23e18][3] = sd(0.028843e18);
        st.sPrimeLong[0.00037e18][23e18][4] = sd(0.037105e18);
        st.sPrimeLong[0.00037e18][23e18][5] = sd(0.044383e18);
        st.sPrimeLong[0.00037e18][23e18][6] = sd(0.05066e18);
        st.sPrimeLong[0.00037e18][23e18][7] = sd(0.055995e18);
        st.sPrimeLong[0.00037e18][23e18][8] = sd(0.060492e18);
        st.sPrimeLong[0.00037e18][23e18][9] = sd(0.064265e18);

        st.sPrimeShort[0.00037e18][23e18] = new SD59x18[](10);
        st.sPrimeShort[0.00037e18][23e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.00037e18][23e18][2] = sd(-0.019736e18);
        st.sPrimeShort[0.00037e18][23e18][3] = sd(-0.028858e18);
        st.sPrimeShort[0.00037e18][23e18][4] = sd(-0.037111e18);
        st.sPrimeShort[0.00037e18][23e18][5] = sd(-0.044358e18);
        st.sPrimeShort[0.00037e18][23e18][6] = sd(-0.050576e18);
        st.sPrimeShort[0.00037e18][23e18][7] = sd(-0.055823e18);
        st.sPrimeShort[0.00037e18][23e18][8] = sd(-0.060203e18);
        st.sPrimeShort[0.00037e18][23e18][9] = sd(-0.060314e18);

        st.sPrimeLong[0.000483e18][23e18] = new SD59x18[](10);
        st.sPrimeLong[0.000483e18][23e18][1] = sd(0.01e18);
        st.sPrimeLong[0.000483e18][23e18][2] = sd(0.019764e18);
        st.sPrimeLong[0.000483e18][23e18][3] = sd(0.028981e18);
        st.sPrimeLong[0.000483e18][23e18][4] = sd(0.037436e18);
        st.sPrimeLong[0.000483e18][23e18][5] = sd(0.044991e18);
        st.sPrimeLong[0.000483e18][23e18][6] = sd(0.051607e18);
        st.sPrimeLong[0.000483e18][23e18][7] = sd(0.05732e18);
        st.sPrimeLong[0.000483e18][23e18][8] = sd(0.062206e18);
        st.sPrimeLong[0.000483e18][23e18][9] = sd(0.066363e18);

        st.sPrimeShort[0.000483e18][23e18] = new SD59x18[](10);
        st.sPrimeShort[0.000483e18][23e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.000483e18][23e18][2] = sd(-0.019768e18);
        st.sPrimeShort[0.000483e18][23e18][3] = sd(-0.028994e18);
        st.sPrimeShort[0.000483e18][23e18][4] = sd(-0.037441e18);
        st.sPrimeShort[0.000483e18][23e18][5] = sd(-0.044968e18);
        st.sPrimeShort[0.000483e18][23e18][6] = sd(-0.051529e18);
        st.sPrimeShort[0.000483e18][23e18][7] = sd(-0.057156e18);
        st.sPrimeShort[0.000483e18][23e18][8] = sd(-0.061928e18);
        st.sPrimeShort[0.000483e18][23e18][9] = sd(-0.062575e18);

        st.sPrimeLong[0.000657e18][0.25e18] = new SD59x18[](10);
        st.sPrimeLong[0.000657e18][0.25e18][1] = sd(0.01e18);
        st.sPrimeLong[0.000657e18][0.25e18][2] = sd(0.019998e18);
        st.sPrimeLong[0.000657e18][0.25e18][3] = sd(0.02999e18);
        st.sPrimeLong[0.000657e18][0.25e18][4] = sd(0.039974e18);
        st.sPrimeLong[0.000657e18][0.25e18][5] = sd(0.049946e18);
        st.sPrimeLong[0.000657e18][0.25e18][6] = sd(0.059904e18);
        st.sPrimeLong[0.000657e18][0.25e18][7] = sd(0.069843e18);
        st.sPrimeLong[0.000657e18][0.25e18][8] = sd(0.079763e18);
        st.sPrimeLong[0.000657e18][0.25e18][9] = sd(0.089658e18);

        st.sPrimeShort[0.000657e18][0.25e18] = new SD59x18[](10);
        st.sPrimeShort[0.000657e18][0.25e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.000657e18][0.25e18][2] = sd(-0.019998e18);
        st.sPrimeShort[0.000657e18][0.25e18][3] = sd(-0.02999e18);
        st.sPrimeShort[0.000657e18][0.25e18][4] = sd(-0.039974e18);
        st.sPrimeShort[0.000657e18][0.25e18][5] = sd(-0.049946e18);
        st.sPrimeShort[0.000657e18][0.25e18][6] = sd(-0.059902e18);
        st.sPrimeShort[0.000657e18][0.25e18][7] = sd(-0.06984e18);
        st.sPrimeShort[0.000657e18][0.25e18][8] = sd(-0.079756e18);
        st.sPrimeShort[0.000657e18][0.25e18][9] = sd(-0.089647e18);

        st.sPrimeLong[0.000947e18][0.1e18] = new SD59x18[](10);
        st.sPrimeLong[0.000947e18][0.1e18][1] = sd(0.01e18);
        st.sPrimeLong[0.000947e18][0.1e18][2] = sd(0.019999e18);
        st.sPrimeLong[0.000947e18][0.1e18][3] = sd(0.029997e18);
        st.sPrimeLong[0.000947e18][0.1e18][4] = sd(0.039991e18);
        st.sPrimeLong[0.000947e18][0.1e18][5] = sd(0.049982e18);
        st.sPrimeLong[0.000947e18][0.1e18][6] = sd(0.059968e18);
        st.sPrimeLong[0.000947e18][0.1e18][7] = sd(0.069948e18);
        st.sPrimeLong[0.000947e18][0.1e18][8] = sd(0.079921e18);
        st.sPrimeLong[0.000947e18][0.1e18][9] = sd(0.089886e18);

        st.sPrimeShort[0.000947e18][0.1e18] = new SD59x18[](10);
        st.sPrimeShort[0.000947e18][0.1e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.000947e18][0.1e18][2] = sd(-0.019999e18);
        st.sPrimeShort[0.000947e18][0.1e18][3] = sd(-0.029997e18);
        st.sPrimeShort[0.000947e18][0.1e18][4] = sd(-0.039991e18);
        st.sPrimeShort[0.000947e18][0.1e18][5] = sd(-0.049982e18);
        st.sPrimeShort[0.000947e18][0.1e18][6] = sd(-0.059967e18);
        st.sPrimeShort[0.000947e18][0.1e18][7] = sd(-0.069947e18);
        st.sPrimeShort[0.000947e18][0.1e18][8] = sd(-0.079919e18);
        st.sPrimeShort[0.000947e18][0.1e18][9] = sd(-0.089882e18);

        st.sPrimeLong[0.000947e18][3e18] = new SD59x18[](10);
        st.sPrimeLong[0.000947e18][3e18][1] = sd(0.01e18);
        st.sPrimeLong[0.000947e18][3e18][2] = sd(0.019978e18);
        st.sPrimeLong[0.000947e18][3e18][3] = sd(0.029901e18);
        st.sPrimeLong[0.000947e18][3e18][4] = sd(0.039742e18);
        st.sPrimeLong[0.000947e18][3e18][5] = sd(0.049469e18);
        st.sPrimeLong[0.000947e18][3e18][6] = sd(0.059056e18);
        st.sPrimeLong[0.000947e18][3e18][7] = sd(0.068479e18);
        st.sPrimeLong[0.000947e18][3e18][8] = sd(0.077715e18);
        st.sPrimeLong[0.000947e18][3e18][9] = sd(0.086744e18);

        st.sPrimeShort[0.000947e18][3e18] = new SD59x18[](10);
        st.sPrimeShort[0.000947e18][3e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.000947e18][3e18][2] = sd(-0.019978e18);
        st.sPrimeShort[0.000947e18][3e18][3] = sd(-0.029903e18);
        st.sPrimeShort[0.000947e18][3e18][4] = sd(-0.039742e18);
        st.sPrimeShort[0.000947e18][3e18][5] = sd(-0.049466e18);
        st.sPrimeShort[0.000947e18][3e18][6] = sd(-0.059045e18);
        st.sPrimeShort[0.000947e18][3e18][7] = sd(-0.068451e18);
        st.sPrimeShort[0.000947e18][3e18][8] = sd(-0.07766e18);
        st.sPrimeShort[0.000947e18][3e18][9] = sd(-0.086648e18);

        st.sPrimeLong[0.000947e18][7.2e18] = new SD59x18[](10);
        st.sPrimeLong[0.000947e18][7.2e18][1] = sd(0.01e18);
        st.sPrimeLong[0.000947e18][7.2e18][2] = sd(0.019946e18);
        st.sPrimeLong[0.000947e18][7.2e18][3] = sd(0.029763e18);
        st.sPrimeLong[0.000947e18][7.2e18][4] = sd(0.039385e18);
        st.sPrimeLong[0.000947e18][7.2e18][5] = sd(0.048748e18);
        st.sPrimeLong[0.000947e18][7.2e18][6] = sd(0.057798e18);
        st.sPrimeLong[0.000947e18][7.2e18][7] = sd(0.066493e18);
        st.sPrimeLong[0.000947e18][7.2e18][8] = sd(0.074801e18);
        st.sPrimeLong[0.000947e18][7.2e18][9] = sd(0.082698e18);

        st.sPrimeShort[0.000947e18][7.2e18] = new SD59x18[](10);
        st.sPrimeShort[0.000947e18][7.2e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.000947e18][7.2e18][2] = sd(-0.019947e18);
        st.sPrimeShort[0.000947e18][7.2e18][3] = sd(-0.029766e18);
        st.sPrimeShort[0.000947e18][7.2e18][4] = sd(-0.039386e18);
        st.sPrimeShort[0.000947e18][7.2e18][5] = sd(-0.048739e18);
        st.sPrimeShort[0.000947e18][7.2e18][6] = sd(-0.057769e18);
        st.sPrimeShort[0.000947e18][7.2e18][7] = sd(-0.066427e18);
        st.sPrimeShort[0.000947e18][7.2e18][8] = sd(-0.074676e18);
        st.sPrimeShort[0.000947e18][7.2e18][9] = sd(-0.08249e18);

        st.sPrimeLong[0.001479e18][0.25e18] = new SD59x18[](10);
        st.sPrimeLong[0.001479e18][0.25e18][1] = sd(0.01e18);
        st.sPrimeLong[0.001479e18][0.25e18][2] = sd(0.019998e18);
        st.sPrimeLong[0.001479e18][0.25e18][3] = sd(0.029993e18);
        st.sPrimeLong[0.001479e18][0.25e18][4] = sd(0.039983e18);
        st.sPrimeLong[0.001479e18][0.25e18][5] = sd(0.049964e18);
        st.sPrimeLong[0.001479e18][0.25e18][6] = sd(0.059936e18);
        st.sPrimeLong[0.001479e18][0.25e18][7] = sd(0.069896e18);
        st.sPrimeLong[0.001479e18][0.25e18][8] = sd(0.079842e18);
        st.sPrimeLong[0.001479e18][0.25e18][9] = sd(0.089772e18);

        st.sPrimeShort[0.001479e18][0.25e18] = new SD59x18[](10);
        st.sPrimeShort[0.001479e18][0.25e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.001479e18][0.25e18][2] = sd(-0.019999e18);
        st.sPrimeShort[0.001479e18][0.25e18][3] = sd(-0.029993e18);
        st.sPrimeShort[0.001479e18][0.25e18][4] = sd(-0.039983e18);
        st.sPrimeShort[0.001479e18][0.25e18][5] = sd(-0.049964e18);
        st.sPrimeShort[0.001479e18][0.25e18][6] = sd(-0.059935e18);
        st.sPrimeShort[0.001479e18][0.25e18][7] = sd(-0.069893e18);
        st.sPrimeShort[0.001479e18][0.25e18][8] = sd(-0.079837e18);
        st.sPrimeShort[0.001479e18][0.25e18][9] = sd(-0.089764e18);

        st.sPrimeLong[0.001479e18][2e18] = new SD59x18[](10);
        st.sPrimeLong[0.001479e18][2e18][1] = sd(0.01e18);
        st.sPrimeLong[0.001479e18][2e18][2] = sd(0.019988e18);
        st.sPrimeLong[0.001479e18][2e18][3] = sd(0.029947e18);
        st.sPrimeLong[0.001479e18][2e18][4] = sd(0.039861e18);
        st.sPrimeLong[0.001479e18][2e18][5] = sd(0.049714e18);
        st.sPrimeLong[0.001479e18][2e18][6] = sd(0.059491e18);
        st.sPrimeLong[0.001479e18][2e18][7] = sd(0.069176e18);
        st.sPrimeLong[0.001479e18][2e18][8] = sd(0.078757e18);
        st.sPrimeLong[0.001479e18][2e18][9] = sd(0.08822e18);

        st.sPrimeShort[0.001479e18][2e18] = new SD59x18[](10);
        st.sPrimeShort[0.001479e18][2e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.001479e18][2e18][2] = sd(-0.019988e18);
        st.sPrimeShort[0.001479e18][2e18][3] = sd(-0.029948e18);
        st.sPrimeShort[0.001479e18][2e18][4] = sd(-0.039861e18);
        st.sPrimeShort[0.001479e18][2e18][5] = sd(-0.049712e18);
        st.sPrimeShort[0.001479e18][2e18][6] = sd(-0.059484e18);
        st.sPrimeShort[0.001479e18][2e18][7] = sd(-0.069159e18);
        st.sPrimeShort[0.001479e18][2e18][8] = sd(-0.078724e18);
        st.sPrimeShort[0.001479e18][2e18][9] = sd(-0.088163e18);

        st.sPrimeLong[0.001479e18][3e18] = new SD59x18[](10);
        st.sPrimeLong[0.001479e18][3e18][1] = sd(0.01e18);
        st.sPrimeLong[0.001479e18][3e18][2] = sd(0.019982e18);
        st.sPrimeLong[0.001479e18][3e18][3] = sd(0.029921e18);
        st.sPrimeLong[0.001479e18][3e18][4] = sd(0.039793e18);
        st.sPrimeLong[0.001479e18][3e18][5] = sd(0.049574e18);
        st.sPrimeLong[0.001479e18][3e18][6] = sd(0.059241e18);
        st.sPrimeLong[0.001479e18][3e18][7] = sd(0.068775e18);
        st.sPrimeLong[0.001479e18][3e18][8] = sd(0.078157e18);
        st.sPrimeLong[0.001479e18][3e18][9] = sd(0.087368e18);

        st.sPrimeShort[0.001479e18][3e18] = new SD59x18[](10);
        st.sPrimeShort[0.001479e18][3e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.001479e18][3e18][2] = sd(-0.019983e18);
        st.sPrimeShort[0.001479e18][3e18][3] = sd(-0.029922e18);
        st.sPrimeShort[0.001479e18][3e18][4] = sd(-0.039793e18);
        st.sPrimeShort[0.001479e18][3e18][5] = sd(-0.049571e18);
        st.sPrimeShort[0.001479e18][3e18][6] = sd(-0.059232e18);
        st.sPrimeShort[0.001479e18][3e18][7] = sd(-0.068753e18);
        st.sPrimeShort[0.001479e18][3e18][8] = sd(-0.078112e18);
        st.sPrimeShort[0.001479e18][3e18][9] = sd(-0.087289e18);

        st.sPrimeLong[0.001479e18][7.2e18] = new SD59x18[](10);
        st.sPrimeLong[0.001479e18][7.2e18][1] = sd(0.01e18);
        st.sPrimeLong[0.001479e18][7.2e18][2] = sd(0.019957e18);
        st.sPrimeLong[0.001479e18][7.2e18][3] = sd(0.02981e18);
        st.sPrimeLong[0.001479e18][7.2e18][4] = sd(0.039506e18);
        st.sPrimeLong[0.001479e18][7.2e18][5] = sd(0.048991e18);
        st.sPrimeLong[0.001479e18][7.2e18][6] = sd(0.05822e18);
        st.sPrimeLong[0.001479e18][7.2e18][7] = sd(0.067155e18);
        st.sPrimeLong[0.001479e18][7.2e18][8] = sd(0.075763e18);
        st.sPrimeLong[0.001479e18][7.2e18][9] = sd(0.084022e18);

        st.sPrimeShort[0.001479e18][7.2e18] = new SD59x18[](10);
        st.sPrimeShort[0.001479e18][7.2e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.001479e18][7.2e18][2] = sd(-0.019958e18);
        st.sPrimeShort[0.001479e18][7.2e18][3] = sd(-0.029813e18);
        st.sPrimeShort[0.001479e18][7.2e18][4] = sd(-0.039506e18);
        st.sPrimeShort[0.001479e18][7.2e18][5] = sd(-0.048984e18);
        st.sPrimeShort[0.001479e18][7.2e18][6] = sd(-0.058196e18);
        st.sPrimeShort[0.001479e18][7.2e18][7] = sd(-0.0671e18);
        st.sPrimeShort[0.001479e18][7.2e18][8] = sd(-0.07566e18);
        st.sPrimeShort[0.001479e18][7.2e18][9] = sd(-0.083847e18);

        st.sPrimeLong[0.00263e18][0.25e18] = new SD59x18[](10);
        st.sPrimeLong[0.00263e18][0.25e18][1] = sd(0.01e18);
        st.sPrimeLong[0.00263e18][0.25e18][2] = sd(0.019999e18);
        st.sPrimeLong[0.00263e18][0.25e18][3] = sd(0.029995e18);
        st.sPrimeLong[0.00263e18][0.25e18][4] = sd(0.039987e18);
        st.sPrimeLong[0.00263e18][0.25e18][5] = sd(0.049973e18);
        st.sPrimeLong[0.00263e18][0.25e18][6] = sd(0.059952e18);
        st.sPrimeLong[0.00263e18][0.25e18][7] = sd(0.069922e18);
        st.sPrimeLong[0.00263e18][0.25e18][8] = sd(0.079881e18);
        st.sPrimeLong[0.00263e18][0.25e18][9] = sd(0.089829e18);

        st.sPrimeShort[0.00263e18][0.25e18] = new SD59x18[](10);
        st.sPrimeShort[0.00263e18][0.25e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.00263e18][0.25e18][2] = sd(-0.019999e18);
        st.sPrimeShort[0.00263e18][0.25e18][3] = sd(-0.029995e18);
        st.sPrimeShort[0.00263e18][0.25e18][4] = sd(-0.039987e18);
        st.sPrimeShort[0.00263e18][0.25e18][5] = sd(-0.049973e18);
        st.sPrimeShort[0.00263e18][0.25e18][6] = sd(-0.059951e18);
        st.sPrimeShort[0.00263e18][0.25e18][7] = sd(-0.06992e18);
        st.sPrimeShort[0.00263e18][0.25e18][8] = sd(-0.079878e18);
        st.sPrimeShort[0.00263e18][0.25e18][9] = sd(-0.089823e18);

        st.sPrimeLong[0.00263e18][1e18] = new SD59x18[](10);
        st.sPrimeLong[0.00263e18][1e18][1] = sd(0.01e18);
        st.sPrimeLong[0.00263e18][1e18][2] = sd(0.019996e18);
        st.sPrimeLong[0.00263e18][1e18][3] = sd(0.02998e18);
        st.sPrimeLong[0.00263e18][1e18][4] = sd(0.039948e18);
        st.sPrimeLong[0.00263e18][1e18][5] = sd(0.049892e18);
        st.sPrimeLong[0.00263e18][1e18][6] = sd(0.059808e18);
        st.sPrimeLong[0.00263e18][1e18][7] = sd(0.069688e18);
        st.sPrimeLong[0.00263e18][1e18][8] = sd(0.079527e18);
        st.sPrimeLong[0.00263e18][1e18][9] = sd(0.089321e18);

        st.sPrimeShort[0.00263e18][1e18] = new SD59x18[](10);
        st.sPrimeShort[0.00263e18][1e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.00263e18][1e18][2] = sd(-0.019996e18);
        st.sPrimeShort[0.00263e18][1e18][3] = sd(-0.02998e18);
        st.sPrimeShort[0.00263e18][1e18][4] = sd(-0.039948e18);
        st.sPrimeShort[0.00263e18][1e18][5] = sd(-0.049892e18);
        st.sPrimeShort[0.00263e18][1e18][6] = sd(-0.059805e18);
        st.sPrimeShort[0.00263e18][1e18][7] = sd(-0.069681e18);
        st.sPrimeShort[0.00263e18][1e18][8] = sd(-0.079515e18);
        st.sPrimeShort[0.00263e18][1e18][9] = sd(-0.089298e18);

        st.sPrimeLong[0.005917e18][0.25e18] = new SD59x18[](10);
        st.sPrimeLong[0.005917e18][0.25e18][1] = sd(0.01e18);
        st.sPrimeLong[0.005917e18][0.25e18][2] = sd(0.019999e18);
        st.sPrimeLong[0.005917e18][0.25e18][3] = sd(0.029997e18);
        st.sPrimeLong[0.005917e18][0.25e18][4] = sd(0.039991e18);
        st.sPrimeLong[0.005917e18][0.25e18][5] = sd(0.049982e18);
        st.sPrimeLong[0.005917e18][0.25e18][6] = sd(0.059968e18);
        st.sPrimeLong[0.005917e18][0.25e18][7] = sd(0.069948e18);
        st.sPrimeLong[0.005917e18][0.25e18][8] = sd(0.079921e18);
        st.sPrimeLong[0.005917e18][0.25e18][9] = sd(0.089886e18);

        st.sPrimeShort[0.005917e18][0.25e18] = new SD59x18[](10);
        st.sPrimeShort[0.005917e18][0.25e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.005917e18][0.25e18][2] = sd(-0.019999e18);
        st.sPrimeShort[0.005917e18][0.25e18][3] = sd(-0.029997e18);
        st.sPrimeShort[0.005917e18][0.25e18][4] = sd(-0.039991e18);
        st.sPrimeShort[0.005917e18][0.25e18][5] = sd(-0.049982e18);
        st.sPrimeShort[0.005917e18][0.25e18][6] = sd(-0.059967e18);
        st.sPrimeShort[0.005917e18][0.25e18][7] = sd(-0.069947e18);
        st.sPrimeShort[0.005917e18][0.25e18][8] = sd(-0.079919e18);
        st.sPrimeShort[0.005917e18][0.25e18][9] = sd(-0.089882e18);

        st.sPrimeLong[0.005917e18][1e18] = new SD59x18[](10);
        st.sPrimeLong[0.005917e18][1e18][1] = sd(0.01e18);
        st.sPrimeLong[0.005917e18][1e18][2] = sd(0.019997e18);
        st.sPrimeLong[0.005917e18][1e18][3] = sd(0.029987e18);
        st.sPrimeLong[0.005917e18][1e18][4] = sd(0.039965e18);
        st.sPrimeLong[0.005917e18][1e18][5] = sd(0.049928e18);
        st.sPrimeLong[0.005917e18][1e18][6] = sd(0.059872e18);
        st.sPrimeLong[0.005917e18][1e18][7] = sd(0.069791e18);
        st.sPrimeLong[0.005917e18][1e18][8] = sd(0.079684e18);
        st.sPrimeLong[0.005917e18][1e18][9] = sd(0.089546e18);

        st.sPrimeShort[0.005917e18][1e18] = new SD59x18[](10);
        st.sPrimeShort[0.005917e18][1e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.005917e18][1e18][2] = sd(-0.019997e18);
        st.sPrimeShort[0.005917e18][1e18][3] = sd(-0.029987e18);
        st.sPrimeShort[0.005917e18][1e18][4] = sd(-0.039965e18);
        st.sPrimeShort[0.005917e18][1e18][5] = sd(-0.049928e18);
        st.sPrimeShort[0.005917e18][1e18][6] = sd(-0.05987e18);
        st.sPrimeShort[0.005917e18][1e18][7] = sd(-0.069787e18);
        st.sPrimeShort[0.005917e18][1e18][8] = sd(-0.079676e18);
        st.sPrimeShort[0.005917e18][1e18][9] = sd(-0.089531e18);

        st.sPrimeLong[0.005917e18][1.5e18] = new SD59x18[](10);
        st.sPrimeLong[0.005917e18][1.5e18][1] = sd(0.01e18);
        st.sPrimeLong[0.005917e18][1.5e18][2] = sd(0.019995e18);
        st.sPrimeLong[0.005917e18][1.5e18][3] = sd(0.02998e18);
        st.sPrimeLong[0.005917e18][1.5e18][4] = sd(0.039948e18);
        st.sPrimeLong[0.005917e18][1.5e18][5] = sd(0.049892e18);
        st.sPrimeLong[0.005917e18][1.5e18][6] = sd(0.059808e18);
        st.sPrimeLong[0.005917e18][1.5e18][7] = sd(0.069688e18);
        st.sPrimeLong[0.005917e18][1.5e18][8] = sd(0.079527e18);
        st.sPrimeLong[0.005917e18][1.5e18][9] = sd(0.089321e18);

        st.sPrimeShort[0.005917e18][1.5e18] = new SD59x18[](10);
        st.sPrimeShort[0.005917e18][1.5e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.005917e18][1.5e18][2] = sd(-0.019996e18);
        st.sPrimeShort[0.005917e18][1.5e18][3] = sd(-0.02998e18);
        st.sPrimeShort[0.005917e18][1.5e18][4] = sd(-0.039948e18);
        st.sPrimeShort[0.005917e18][1.5e18][5] = sd(-0.049892e18);
        st.sPrimeShort[0.005917e18][1.5e18][6] = sd(-0.059805e18);
        st.sPrimeShort[0.005917e18][1.5e18][7] = sd(-0.069681e18);
        st.sPrimeShort[0.005917e18][1.5e18][8] = sd(-0.079515e18);
        st.sPrimeShort[0.005917e18][1.5e18][9] = sd(-0.089298e18);

        st.sPrimeLong[0.023669e18][0.25e18] = new SD59x18[](10);
        st.sPrimeLong[0.023669e18][0.25e18][1] = sd(0.01e18);
        st.sPrimeLong[0.023669e18][0.25e18][2] = sd(0.02e18);
        st.sPrimeLong[0.023669e18][0.25e18][3] = sd(0.029998e18);
        st.sPrimeLong[0.023669e18][0.25e18][4] = sd(0.039996e18);
        st.sPrimeLong[0.023669e18][0.25e18][5] = sd(0.049991e18);
        st.sPrimeLong[0.023669e18][0.25e18][6] = sd(0.059984e18);
        st.sPrimeLong[0.023669e18][0.25e18][7] = sd(0.069974e18);
        st.sPrimeLong[0.023669e18][0.25e18][8] = sd(0.07996e18);
        st.sPrimeLong[0.023669e18][0.25e18][9] = sd(0.089943e18);

        st.sPrimeShort[0.023669e18][0.25e18] = new SD59x18[](10);
        st.sPrimeShort[0.023669e18][0.25e18][1] = sd(-0.01e18);
        st.sPrimeShort[0.023669e18][0.25e18][2] = sd(-0.02e18);
        st.sPrimeShort[0.023669e18][0.25e18][3] = sd(-0.029998e18);
        st.sPrimeShort[0.023669e18][0.25e18][4] = sd(-0.039996e18);
        st.sPrimeShort[0.023669e18][0.25e18][5] = sd(-0.049991e18);
        st.sPrimeShort[0.023669e18][0.25e18][6] = sd(-0.059984e18);
        st.sPrimeShort[0.023669e18][0.25e18][7] = sd(-0.069973e18);
        st.sPrimeShort[0.023669e18][0.25e18][8] = sd(-0.079959e18);
        st.sPrimeShort[0.023669e18][0.25e18][9] = sd(-0.089941e18);
    }

    function setUp() public {
        removeMarketsOILimit();
        mockFreshPrices();
    }

    function trade_slippage_helper(uint128 marketId, UD60x18 eps, bool isLong, uint256 iterations) internal {
        st.marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        st.a = ICoreProxy(sec.core).getRiskBlockMatrixByMarket(marketId)[st.marketConfig.riskMatrixIndex][st
            .marketConfig
            .riskMatrixIndex];

        st.s = (isLong) ? st.sLong : st.sShort;
        st.sPrime = (isLong)
            ? st.sPrimeLong[st.a][st.marketConfig.depthFactor]
            : st.sPrimeShort[st.a][st.marketConfig.depthFactor];

        assertEq(st.s.length, st.sPrime.length);

        (st.user,) = makeAddrAndKey("user");

        // deposit new margin account
        uint256 depositAmount = 100_000_000e18;
        deal(sec.usdc, address(sec.periphery), depositAmount);
        mockBridgedAmount(dec.socketExecutionHelper[sec.usdc], depositAmount);
        vm.prank(dec.socketExecutionHelper[sec.usdc]);
        uint128 accountId = IPeripheryProxy(sec.periphery).depositNewMA(
            DepositNewMAInputs({ accountOwner: st.user, token: address(sec.usdc) })
        );

        for (uint128 _marketId = 1; _marketId <= lastMarketId(); _marketId += 1) {
            if (_marketId == 19) {
                continue;
            }

            st.marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(_marketId);

            // Step 1: Unwind any exposure of the pool
            st.poolBase = SD59x18.wrap(
                IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(_marketId, sec.passivePoolAccountId).base
            );

            if (st.poolBase.abs().gt(sd(int256(st.marketConfig.minimumOrderBase)))) {
                SD59x18 base = st.poolBase.sub(st.poolBase.mod(sd(int256(st.marketConfig.baseSpacing))));
                executeCoreMatchOrder({
                    marketId: _marketId,
                    sender: st.user,
                    base: base,
                    priceLimit: getPriceLimit(base),
                    accountId: accountId
                });

                st.poolBase = SD59x18.wrap(
                    IPassivePerpProxy(sec.perp).getUpdatedPositionInfo(_marketId, sec.passivePoolAccountId).base
                );

                // assertEq(IPassivePerpProxy(perp).getUpdatedPositionInfo(_marketId, passivePoolAccountId).base, 0);
            }
        }

        st.passivePoolImMultiplier = ICoreProxy(sec.core).getAccountImMultiplier(sec.passivePoolAccountId);
        st.marketRiskMatrix = ICoreProxy(sec.core).getRiskBlockMatrixByMarket(marketId);

        // increase max open base
        st.marketConfig = IPassivePerpProxy(sec.perp).getMarketConfiguration(marketId);
        st.marketConfig.maxOpenBase = 100_000_000_000e18;
        vm.prank(sec.multisig);
        IPassivePerpProxy(sec.perp).setMarketConfiguration(marketId, st.marketConfig);

        // Step 2: Get pool's TVL
        MarginInfo memory poolMarginInfo = ICoreProxy(sec.core).getUsdNodeMarginInfo(sec.passivePoolAccountId);
        SD59x18 passivePoolTVL = sd(poolMarginInfo.marginBalance);

        // Step 3: Compute the grid
        SD59x18 prevNotionalsSum = sd(0);
        for (uint256 i = 1; i < st.s.length && iterations > 0; i += 1) {
            iterations -= 1;

            SD59x18 notional = st.s[i].div(UNIT_sd.add(st.s[i])).mul(
                sd(int256(st.marketConfig.depthFactor)).mul(passivePoolTVL).div(
                    sd(int256(st.passivePoolImMultiplier)).mul(
                        sd(st.marketRiskMatrix[st.marketConfig.riskMatrixIndex][st.marketConfig.riskMatrixIndex]).sqrt()
                    )
                )
            ).sub(prevNotionalsSum);
            SD59x18 base = exposureToBase(marketId, notional);
            base = base.sub(base.mod(sd(int256(st.marketConfig.baseSpacing))));

            (, st.pSlippage) = executeCoreMatchOrder({
                marketId: marketId,
                sender: st.user,
                base: base,
                priceLimit: getPriceLimit(base),
                accountId: accountId
            });

            assertApproxEqAbsDecimal(st.pSlippage.unwrap(), st.sPrime[i].unwrap(), eps.unwrap(), 18);

            prevNotionalsSum = prevNotionalsSum.add(baseToExposure(marketId, base));
        }
    }

    function check_trade_slippage_eth_long() public {
        trade_slippage_helper({ marketId: 1, eps: ud(0.001e18), isLong: true, iterations: 5 });
    }

    function check_trade_slippage_btc_long() public {
        trade_slippage_helper({ marketId: 2, eps: ud(0.002e18), isLong: true, iterations: 5 });
    }

    function check_trade_slippage_sol_long() public {
        trade_slippage_helper({ marketId: 3, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_arb_long() public {
        trade_slippage_helper({ marketId: 4, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_op_long() public {
        trade_slippage_helper({ marketId: 5, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_avax_long() public {
        trade_slippage_helper({ marketId: 6, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_mkr_long() public {
        trade_slippage_helper({ marketId: 7, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_link_long() public {
        trade_slippage_helper({ marketId: 8, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_aave_long() public {
        trade_slippage_helper({ marketId: 9, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_crv_long() public {
        trade_slippage_helper({ marketId: 10, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_uni_long() public {
        trade_slippage_helper({ marketId: 11, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_sui_long() public {
        trade_slippage_helper({ marketId: 12, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_tia_long() public {
        trade_slippage_helper({ marketId: 13, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_sei_long() public {
        trade_slippage_helper({ marketId: 14, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_zro_long() public {
        trade_slippage_helper({ marketId: 15, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_xrp_long() public {
        trade_slippage_helper({ marketId: 16, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_wif_long() public {
        trade_slippage_helper({ marketId: 17, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_pepe1k_long() public {
        trade_slippage_helper({ marketId: 18, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_popcat_long() public {
        trade_slippage_helper({ marketId: 19, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_doge_long() public {
        trade_slippage_helper({ marketId: 20, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_kshib_long() public {
        trade_slippage_helper({ marketId: 21, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_kbonk_long() public {
        trade_slippage_helper({ marketId: 22, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_apt_long() public {
        trade_slippage_helper({ marketId: 23, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_bnb_long() public {
        trade_slippage_helper({ marketId: 24, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_jto_long() public {
        trade_slippage_helper({ marketId: 25, eps: ud(0.002e18), isLong: true, iterations: 9 });
    }

    function check_trade_slippage_eth_short() public {
        trade_slippage_helper({ marketId: 1, eps: ud(0.001e18), isLong: false, iterations: 4 });
    }

    function check_trade_slippage_btc_short() public {
        trade_slippage_helper({ marketId: 2, eps: ud(0.001e18), isLong: false, iterations: 4 });
    }

    function check_trade_slippage_sol_short() public {
        trade_slippage_helper({ marketId: 3, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_arb_short() public {
        trade_slippage_helper({ marketId: 4, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_op_short() public {
        trade_slippage_helper({ marketId: 5, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_avax_short() public {
        trade_slippage_helper({ marketId: 6, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_mkr_short() public {
        trade_slippage_helper({ marketId: 7, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_link_short() public {
        trade_slippage_helper({ marketId: 8, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_aave_short() public {
        trade_slippage_helper({ marketId: 9, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_crv_short() public {
        trade_slippage_helper({ marketId: 10, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_uni_short() public {
        trade_slippage_helper({ marketId: 11, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_sui_short() public {
        trade_slippage_helper({ marketId: 12, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_tia_short() public {
        trade_slippage_helper({ marketId: 13, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_sei_short() public {
        trade_slippage_helper({ marketId: 14, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_zro_short() public {
        trade_slippage_helper({ marketId: 15, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_xrp_short() public {
        trade_slippage_helper({ marketId: 16, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_wif_short() public {
        trade_slippage_helper({ marketId: 17, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_pepe1k_short() public {
        trade_slippage_helper({ marketId: 18, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_popcat_short() public {
        trade_slippage_helper({ marketId: 19, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_doge_short() public {
        trade_slippage_helper({ marketId: 20, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_kshib_short() public {
        trade_slippage_helper({ marketId: 21, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_kbonk_short() public {
        trade_slippage_helper({ marketId: 22, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_apt_short() public {
        trade_slippage_helper({ marketId: 23, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_bnb_short() public {
        trade_slippage_helper({ marketId: 24, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }

    function check_trade_slippage_jto_short() public {
        trade_slippage_helper({ marketId: 25, eps: ud(0.001e18), isLong: false, iterations: 9 });
    }
}
