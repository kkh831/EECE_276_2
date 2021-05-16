% Transform img to binary sequence
img = imread('Lena.png');% 일단 img 변수와 imread 명령을 통해 Lena.png 이미지를 배열의 형태로 불러온다.
img = imresize(img, 0.25);% 이미지의 bit수를 줄인다. 넓이와 높이가 같은 비율로 축소되며, 0.25를 default로 가정하여 주석을 작성하였다. // 보내는 bit의 수를 줄이려면 0.25보다 작은 수를 대입 (bit수 바뀔시 Rx의 다른 파라미터도 수정)
img = imbinarize(img);% 축소된 이미지의 각 픽셀을 1과 0으로 binarize하여 저장한다.

bits = img(:).';% binarize를 거친 이미지의 1, 0 값을 bits라는 열벡터에 형태 변경하여 저장한다.

A = [ 1 1 1;1 1 0;1 0 1;0 1 1 ];%Parity submatrix-Need binary(decimal combination of 7,6,5,3)            
G = [ eye(4) A ];%Generator matrix
chan = [];
for i = 0:1023
    chan = [chan mod(bits(4*i+1:4*i+4)*G,2)];
end
bits = chan';

% Generate modulator (bit를 여러가지 주파수 신호를 이용하여 modulate)
i = 1:16;% modulator의 행 개수에 대한 변수이다. 행 단위로 연산하기 때문에 i를 사용한 for문이 존재한다.
t = 1:2000;% 44100과 함께 symbol duration을 구성한다. 특정 주파수에 대해 유효한 값을 가지는 시간적 길이를 나타낸다.
tg = 1:2000;% symbol duration과 함께 modulator의 폭을 결정한다. modulator 값을 연산할 때에 symbol duration 이내의 값만 유효하기 때문에 tg의 범위에서는 0을 유지한다.
Fs = 500*i + 8000;% sampling frequency이다. 각각의 bit에 서로 다른 frequency를 부여함으로써 이후 receiver 단계에서 DTFT를 통해 demodulation이 가능하도록 한다.
Modulator = zeros(i(end),t(end)+tg(end));% 먼저 16x4000의 배열로 modulator를 선언해준다.
for i = 1:length(i)% for 문을 i로 구분하여, modulator에 값을 입력할 때 행의 단위로 진행되도록 한다.
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i));% 지정한 t와 i의 범위를 통해 여러 주파수를 생성하고 그 양상을 modulator 배열에 저장한다. 앞서 말한 것처럼 symbol duration 이후에는 0값을 유지하며, Fs가 i에 대한 의존성을 가지므로 송신하는 각각이 bit에 대한 차별성을 부여할 수 있다.
end

% Create preamble (length 64)
preamble = zeros(1,16000);% 16000개의 값을 저장할 수 있는 단일 행의 배열을 선언해준다.
tp = 1:12000;% modulator에서와 같이 preamble 신호에서 유효한 기간을 나타낸다. 16000개의 data 중 tp의 길이에 해당하는 만큼의 data를 제외한 나머지는 0을 유지한다.
for i = 1:16% modulator의 높이가 16인 것과 같은 문맥에 있다. preamble이 modulator와 동일한 주파수의 중첩으로 구성되기 위함이다.
    preamble(tp) = preamble(tp) + sin(2*pi*tp/44100*Fs(i));% 0으로 차있던 단일 행의 행렬에 preamble 신호값을 입력해준다. 다른 data의 개입 없이 modulator와 동일한 주파수의 신호를 중첩적으로 쌓아 preamble의 특수성을 부여한다.
end

% Modulate bits to sinusoidal signal
Bits = reshape(bits,[16,length(bits)/16]).';% 기존에 저장하였던 bits에 대한 값을 16개의 행으로 나눈 새로운 형태의 행렬 Bits로 저장한다. 추가로, transpose를 취한다.
data = [];% 배열 형태의 data 변수 선언
for i = 1:size(Bits,1)% Bits에 transpose를 취하였으므로 행 방향으로 연산을 진행할 수 있도록 한다. 즉, i는 행의 순서를 취급한다.
    data = [data Bits(i,:)*Modulator];% 기존에 선언한 Bits 배열의 각 행과 modulator의 행렬곱을 취한 뒤 data 배열에 순서대로 추가한다. modulator의 높이가 16이기 때문에 16개의 bit씩 modulation 과정을 거친다. 16개의 bit가 16개의 주파수에 각각 mapping 되어 modulation 처리된 신호를 생성하는 것이다.
end
x = [preamble data];% transmitter의 모든 과정을 끝낸 후, 구분을 위한 preamble 신호를 가장 앞에 삽입하여 전송할 신호를 완성한다.
x = x./max(x);% 신호의 max값으로 각각을 나누어 normalize한다.
sound(x,44100)% 위 과정에서와 동일하게 sampling rate는 44.1kHz를 사용하고, normalize까지 마친 신호를 출력한다.

%audiowrite('sound.wav',x,44100);% 노트북 한 대로 진행하였기 때문에 신호를 음파 파일로 형성하였다.