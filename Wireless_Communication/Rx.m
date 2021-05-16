clear;%�ʱ��� ��� ���� ����. ������ �˸��� �κ�.
% Create an audioDeviceReader System object
deviceReader = audioDeviceReader;%audioDeviceReader ����� ���� ���� deviceReader ����.
setup(deviceReader);%deviceReader�� ���� initialization. �� �״�� deviceReader�� ���� ����� �غ�.

%% Record 25 seconds of sound
disp('Recording...')%Recording... ������ ǥ���Ͽ� ���� �¾��� �� ����� ���� �Է� ��ȣ ������ �������� ���Ѵ�.
tic;%��ž��ġ�� �۵��ϱ� ������.
Signal = [];%Signal �迭�� ������. ���� ���� ������� �����.
while toc < 27%��ž��ġ�� �۵��� ���� 25�ʱ����� ���ؼ��� �����Ѵ�.
    acquiredAudio = deviceReader();% acquiredAudio�� ����ũ �Է��� ���� ������ ��ȣ�� ����Ѵ�. �տ��� ������ deviceReader�� ���� ���� �Էµȴ�.
    Signal = [Signal; acquiredAudio];% ����ũ�� �ԷµǴ� ��ȣ�� Signal �迭�� �� �������� ������� �׾� �����Ѵ�.
end
disp('Recording complete.')% toc�� ���� 25�ʸ� ī��Ʈ�� ��, Recording complete ������ ���� ��ȣ ������ �Ϸ�Ǿ����� ǥ���Ѵ�.
Signal = Signal.';% ������ ���� ������ ���� Signal ��Ŀ� transpose�� ���Ѵ�. �ϳ��� �� ���¿��� �ϳ��� �� ���·� ��ȯ��.

%% Syncronize
preamble = zeros(1,16000);% preamble ��ȣ�� zeros�� ���� �������ش�. �� ���̴� transmitter������ ���� ���ƾ� �Ѵ�.
tp = 1:12000;% preamble ��ȣ�� ��ȿ�� �����̴�. ��ü 16000 data �� 12000 data�� ������ �������� ó�� �����Ѵ�� 0�� �����Ѵ�. �� ���� ���� transmitter������ ���� ���ƾ� �Ѵ�.
for i= 1:28
    preamble(tp) = preamble(tp) + sin(2*pi*tp/44100*(8000+500*i));% �� �κ��� transmitter �κп����� preamble ���� ������ ����. transmitter�� receiver���� ���� ��ȣ�� ����ϱ� �����̴�.
end
[xC, lags] = xcorr(Signal, preamble);% 25�ʰ� �Է��� ��ȣ��, transmitter�� �����ϰ� ������ preamble�� ���Ͽ� �������� ���� correlation value�� �����Ѵ�.
[~, idx] = max(xC);% �� �ٿ��� ������ �������� correlation value �� correlation value�� ���� ū ������, �� preamble�� delay�� ���Ͽ� idx output�� �����Ѵ�.
startPoint = lags(idx);% max(xC)���� ���� lags�� startPoint�� �����Ѵ�. transmitter ��ȣ�� receiver ��ȣ ������ synchronization �����̴�.

%% Equalize (Demodulation�� �ʿ��� threshold ���, ���Ƿ� ��ü����)
rPreamble = Signal(startPoint:startPoint+15999);% rPreamble�� ������ ���۵� ���� Preamble�� ��ġ�� �ľ��Ͽ� ������ ���̴�. ������ synchronization�� ���� ã�� startPoint�� ��������, Preamble�� ���̸� ���� rPreamble�� ������ ������ �� �ִ�. Preamble�� ���̴� transmitter �ܰ迡�� zeros(1, 16000) �� ���� 16000���� ����Ǿ���.
Data = Signal(startPoint+16000:end);% Transmitter �ܰ迡��, ������ ���� ��ȣ �տ� preamble�� �߰��� �����ߴ�. ������ rPreamble�� ���� preamble�� ��ġ�� ã�Ҵٸ� �� �޺κ��� ������ ���� ��ȣ���� �� �� �ִ�. �� �κ��� Data�� ���� �����Ͽ� ���� detection & demodulation �ܰ踦 ��ģ��.
Resp = zeros(1,28);% ���� ��ȣ�� �����ϱ� ���� rPreamble������ �����̴�. DFTF ���� �� periodogram�� ���Եȴ�.
tt = 1:16000;% rPreamble�� ����. �� ���̿� ���� DTFT�� �����Ѵ�.
for i = 1:28% modulation�� 16���� bit�� ����Ǿ��� ������ demodulation ���� 16���� bit�� �����Ͽ� ���������� �����Ѵ�.
    Resp(i) = abs(sum(rPreamble.*exp(-1i*2*pi*tt/44100*(8000+500*i)))).^2;% rPreamble�� ���� DTFT�� ����. periodogram * N�� ���̴�. N���� ������ ���� ������ ���� threshold�� ���ԵǾ� �ֱ� �����̴�. ���� data�� DTFT�� ���Ͽ� threshold�� ���ϴ� ������ �ȴ�.
end
% preamble�� �� ���ļ��� �Ŀ��� �����Ͽ� threshold ����
%% Detection & Demodulation
bits = [];% ������ ��ȣ�� demodulation�� ���� �������� ��ȣ�� �ؼ��Ͽ� �����ϱ� ���� �迭.
tt = 1:2000;% symbol duration�� �����̴�(44100�� �Բ�). ��� modulator�� ���� ��ü�� ����ϴ� ���� ��Ȯ������, symbol duration ���Ŀ��� modulator�� ���� 0�̱� ������ ���� �����̴�.
while(length(Data)>=4000)% tranmitter �κп��� modulation ��İ� ������ modulator�� ���̿� ���� 16���� bit�� ����Ǿ���. ����, modulator�� ���� ���� 4000���� data�� �����Ǿ���. ��, demodulation�� 4000���� �����Ͽ� 16���� ���� ��ȯ�Ѵ�.
    data = Data(1:2000);% demodulation ������ 4000���� �����ϴ� ���� ������, symbol duration�� ���� modulator�� 2001��° data ���ʹ� �� ���� 0�̴�. ���� modulation�� ��ģ ���� 0�� ���̰�, demodulation �������� ����ϴ� DTFT�� ��ǻ� ���Խ�ų �ʿ䰡 ����. DTFT�� ���� ������ ����ϰ�, 2001��° Data���� ��� 0�̱� ������ DTFT ����� ������ ��ġ�� �ʱ� �����̴�.
    Data = Data(4001:end);% ó�� 4000���� Data�� ���� ������ ��, Data�� ó�� 4000���� �����Ѵ�. while ���� ���ǿ� ���� ���������.
    resp = zeros(1,28);% ���� ��ȣ�� �����ϱ� ���� bits������ �����̴�. DTFT ���� �� periodogram�� ���Եȴ�.
    for k = 1:28% 4000���� ������� demodulation�� �����ϸ� 16���� output�� �����ȴ�. output�� DTFT ���� �������ν� �տ��� ���� rPreamble�� DTFT ���� �� ������ ��ġ�� �ȴ�.
        resp(k) = abs(sum(data.*exp(-1i*2*pi*tt/44100*(8000+500*k)))).^2;% 4000���� Data�� 2000���� �����ϰ� ���� 2000���� ���� ���� DTFT�� ����. periodogram * N�� ���̴�. rPreamble�� Resp�� ���Ͽ� threshold�� �������� ���� ��ȣ�� bit ���� ���Ѵ�.
    end
    resp = resp./Resp;% 16���� periodogram�� �����Ǿ���. �̸� rPreamble�� periodogram ������ ������ ���� �����Ѵ�. threshold���� �񱳰� �̷������.
    bits = [bits resp>0.002];% threshold ������ 1, �ƴϸ� 0 // resp���� 0�� 1�� binarize�Ͽ� ������� �����Ѵ�. �۽��� ��ȣ�� �������� ���������� �巯���� �κ��̴�.
end

A = [ 1 1 1;1 1 0;1 0 1;0 1 1 ];
H = [ A' eye(3) ];
find = 0;
correct = [];
index = 7;
for i = 0:1023
    syndrome = mod(bits(i*7+1:i*7+7)*H',2);
    for ii = 1:7
    if ~find
        errvect = zeros(1,7);
        errvect(ii) = 1;
        search = mod(errvect * H',2);
        if search == syndrome
            find = 1;
            index = ii;
        end
    end
    end    
    correct = [correct bits(i*7+1:i*7+7)];
    correct(length(correct)-(7-index)) = mod(correct(length(correct)-(7-index))+1,2);
    correct = correct(1:length(correct)-3);
end
%% Plot
img_bits = zeros(1,64*64);% ������ ��ȣ�� �����ϱ� ���� �迭.
img_bits(1:length(bits)) = bits;% �̸� ;������ �迭�� �ռ� ���� binarization�� bit data�� �����Ѵ�.
img_hat = reshape(img_bits.',[64,64]);% bit data�� �������� �׸��� ���·�, �� 64x64 �迭�� �������Ѵ�.
imshow(img_hat)% ������ bit�� ǥ���Ѵ�.

pspectrum(Signal,44100,'spectrogram')% 44100Hz�� sampling rate�� ������ Signal�� spectrum�� ǥ���Ѵ�.

release(deviceReader);% ������ ��ģ��.