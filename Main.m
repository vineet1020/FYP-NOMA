function Main()

    sysPower = 1;
    
    %% System Initialisation

    % rng function is used to control the random number generation process.
    % Here, seed is set to 65
    rng(65);

    % Initialising System Parameters
    System_Parameters = Parameters();
    
    %% Uplink Channel Estimation

    % Simulate UE Uplink Tx
    N = System_Parameters.OFDM.N;
    cp = System_Parameters.OFDM.cp;
    
    ULTx_Stream = UplinkTx(System_Parameters);
    
    disp(ULTx_Stream)
    % Adding a Single Tap Rayleigh fading channel and AWGN Noise
    System_Parameters.CSI = (1 / sqrt(2)) * (randn(1, System_Parameters.numUsers) + 1i * randn(1, System_Parameters.numUsers));
    UL_Noise = (1 / sqrt(2 * System_Parameters.SNR * N)) * (randn((N + cp), System_Parameters.numUsers) + 1i * randn((N + cp), System_Parameters.numUsers));
    ULRx_Stream = ULTx_Stream .* System_Parameters.CSI + UL_Noise;
    
    % Estimating CSI
    System_Parameters.est_CSI = UplinkRx(ULRx_Stream, System_Parameters);
    [~, System_Parameters.sorted_CSI_Idx] = sort(System_Parameters.est_CSI, 'descend');

    disp(System_Parameters.CSI)
    disp(System_Parameters.est_CSI)
    
    %% Generating Data

    % Generating random data
    txBitStreamMat = randi([0, 1], System_Parameters.dataLength - System_Parameters.coding.cc.tbl, System_Parameters.numUsers);
    txBitStreamMat = [txBitStreamMat; zeros(System_Parameters.coding.cc.tbl, System_Parameters.numUsers)];
    %% Data Processing at Tx
    % Passing the data for transmission

    [txOut, System_Parameters] = Transmitter(txBitStreamMat, System_Parameters);

    %% Channel Model

    % For Simulation purposes, the flat fading channel will added at the receiver
    
    % Noise

    SNR = System_Parameters.SNR;
    noise = (sqrt(sysPower) / sqrt(2 * SNR)) .* (randn(size(txOut)) + (1i) * randn(size(txOut)));
    
   rxDataStream = txOut + noise;


    %% Receiver
    % Detecting the information from received signal
    rxBitStreamMat = Receiver(rxDataStream, System_Parameters);

    % Error in received bitstream
    errBits = sum(bitxor(txBitStreamMat, rxBitStreamMat));

    if (~errBits)
        disp('Successful Transmission');
    else
        disp(['Err Bits: ', num2str(errBits)]);
    end

    disp(System_Parameters.CSI);
    disp(System_Parameters.CSI(System_Parameters.sorted_CSI_Idx));
end

