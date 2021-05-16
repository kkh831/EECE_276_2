clear;%초기의 모든 변수 제거. 시작을 알리는 부분.
% Create an audioDeviceReader System object
deviceReader = audioDeviceReader;%audioDeviceReader 기능을 위한 변수 deviceReader 선언.
setup(deviceReader);%deviceReader에 대한 initialization. 말 그대로 deviceReader에 대한 사용을 준비.

%% Record 25 seconds of sound
disp('Recording...')%Recording... 문구를 표시하여 위의 셋업이 잘 실행된 이후 입력 신호 저장을 시작함을 뜻한다.
tic;%스탑워치가 작동하기 시작함.
Signal = [];%Signal 배열을 선언함. 이후 수신 오디오가 저장됨.
while toc < 27%스탑워치가 작동한 이후 25초까지에 대해서만 실행한다.
    acquiredAudio = deviceReader();% acquiredAudio는 마이크 입력을 통해 들어오는 신호를 취급한다. 앞에서 선언한 deviceReader를 통해 값이 입력된다.
    Signal = [Signal; acquiredAudio];% 마이크로 입력되는 신호를 Signal 배열에 열 방향으로 순서대로 쌓아 저장한다.
end
disp('Recording complete.')% toc를 통해 25초를 카운트한 후, Recording complete 문구를 통해 신호 저장이 완료되었음을 표시한다.
Signal = Signal.';% 이후의 연산 과정을 위해 Signal 행렬에 transpose를 취한다. 하나의 열 형태에서 하나의 행 형태로 변환됨.

%% Syncronize
preamble = zeros(1,16000);% preamble 신호를 zeros를 통해 선언해준다. 그 길이는 transmitter에서의 경우와 같아야 한다.
tp = 1:12000;% preamble 신호의 유효한 구간이다. 전체 16000 data 중 12000 data를 제외한 나머지는 처음 선언한대로 0을 유지한다. 이 길이 또한 transmitter에서의 경우와 같아야 한다.
for i= 1:28
    preamble(tp) = preamble(tp) + sin(2*pi*tp/44100*(8000+500*i));% 이 부분은 transmitter 부분에서의 preamble 생성 과정과 같다. transmitter와 receiver에서 같은 신호를 취급하기 때문이다.
end
[xC, lags] = xcorr(Signal, preamble);% 25초간 입력한 신호와, transmitter와 동일하게 생성한 preamble을 비교하여 지연값에 대한 correlation value를 저장한다.
[~, idx] = max(xC);% 윗 줄에서 저장한 지연값과 correlation value 중 correlation value가 가장 큰 지연값, 즉 preamble의 delay를 구하여 idx output에 저장한다.
startPoint = lags(idx);% max(xC)값을 갖는 lags를 startPoint로 지정한다. transmitter 신호와 receiver 신호 사이의 synchronization 과정이다.

%% Equalize (Demodulation에 필요한 threshold 계산, 임의로 대체가능)
rPreamble = Signal(startPoint:startPoint+15999);% rPreamble은 녹음이 시작된 이후 Preamble의 위치를 파악하여 저장한 것이다. 위에서 synchronization을 통해 찾은 startPoint를 기준으로, Preamble의 길이를 더해 rPreamble을 적절히 추출할 수 있다. Preamble의 길이는 transmitter 단계에서 zeros(1, 16000) 즉 길이 16000으로 선언되었다.
Data = Signal(startPoint+16000:end);% Transmitter 단계에서, 생성한 음파 신호 앞에 preamble을 추가해 전송했다. 위에서 rPreamble을 통해 preamble의 위치를 찾았다면 그 뒷부분은 생성된 음파 신호임을 알 수 있다. 이 부분을 Data에 따로 저장하여 이후 detection & demodulation 단계를 거친다.
Resp = zeros(1,28);% 수신 신호를 결정하기 위한 rPreamble에서의 수단이다. DFTF 과정 및 periodogram이 포함된다.
tt = 1:16000;% rPreamble의 길이. 이 길이에 대한 DTFT를 진행한다.
for i = 1:28% modulation이 16개의 bit씩 진행되었기 때문에 demodulation 또한 16개의 bit씩 진행하여 순차적으로 저장한다.
    Resp(i) = abs(sum(rPreamble.*exp(-1i*2*pi*tt/44100*(8000+500*i)))).^2;% rPreamble에 대한 DTFT의 제곱. periodogram * N의 꼴이다. N으로 나누지 않은 이유는 이후 threshold에 포함되어 있기 때문이다. 이후 data의 DTFT와 비교하여 threshold를 정하는 기준이 된다.
end
% preamble의 각 주파수별 파워를 참고하여 threshold 정함
%% Detection & Demodulation
bits = [];% 수신한 신호를 demodulation을 통해 실질적인 신호로 해석하여 저장하기 위한 배열.
tt = 1:2000;% symbol duration의 길이이다(44100과 함께). 사실 modulator의 길이 전체를 취급하는 것이 정확하지만, symbol duration 이후에는 modulator의 값이 0이기 때문에 같은 조건이다.
while(length(Data)>=4000)% tranmitter 부분에서 modulation 행렬곱 과정은 modulator의 높이에 따라 16개의 bit씩 진행되었다. 또한, modulator의 폭에 따라 4000개의 data가 생성되었다. 즉, demodulation은 4000개씩 진행하여 16개의 값을 반환한다.
    data = Data(1:2000);% demodulation 과정은 4000개씩 진행하는 것이 맞지만, symbol duration에 의해 modulator의 2001번째 data 부터는 그 값이 0이다. 따라서 modulation을 거친 값도 0일 것이고, demodulation 과정에서 사용하는 DTFT에 사실상 포함시킬 필요가 없다. DTFT는 합의 연산을 사용하고, 2001번째 Data들은 모두 0이기 때문에 DTFT 결과에 영향을 미치지 않기 때문이다.
    Data = Data(4001:end);% 처음 4000개의 Data를 따로 추출한 뒤, Data의 처음 4000개는 삭제한다. while 문의 조건에 점차 가까워진다.
    resp = zeros(1,28);% 수신 신호를 결정하기 위한 bits에서의 수단이다. DTFT 과정 및 periodogram이 포함된다.
    for k = 1:28% 4000개의 대상으로 demodulation을 진행하면 16개의 output이 생성된다. output은 DTFT 값의 제곱으로써 앞에서 구한 rPreamble의 DTFT 값과 비교 과정을 거치게 된다.
        resp(k) = abs(sum(data.*exp(-1i*2*pi*tt/44100*(8000+500*k)))).^2;% 4000개의 Data중 2000개를 제외하고 남은 2000개의 값에 대한 DTFT의 제곱. periodogram * N의 꼴이다. rPreamble의 Resp와 비교하여 threshold를 기준으로 수신 신호의 bit 값을 정한다.
    end
    resp = resp./Resp;% 16개의 periodogram이 생성되었다. 이를 rPreamble의 periodogram 값으로 나누어 새로 저장한다. threshold와의 비교가 이루어진다.
    bits = [bits resp>0.002];% threshold 넘으면 1, 아니면 0 // resp값을 0과 1로 binarize하여 순서대로 저장한다. 송신한 신호가 무엇인지 직접적으로 드러나는 부분이다.
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
img_bits = zeros(1,64*64);% 수신한 신호를 저장하기 위한 배열.
img_bits(1:length(bits)) = bits;% 미리 ;선언한 배열에 앞서 구한 binarization된 bit data를 저장한다.
img_hat = reshape(img_bits.',[64,64]);% bit data를 바탕으로 그림의 형태로, 즉 64x64 배열로 재조합한다.
imshow(img_hat)% 정돈된 bit를 표시한다.

pspectrum(Signal,44100,'spectrogram')% 44100Hz의 sampling rate로 구분한 Signal의 spectrum을 표시한다.

release(deviceReader);% 과정을 마친다.