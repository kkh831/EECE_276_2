% Transform img to binary sequence
img = imread('Lena.png');% �ϴ� img ������ imread ����� ���� Lena.png �̹����� �迭�� ���·� �ҷ��´�.
img = imresize(img, 0.25);% �̹����� bit���� ���δ�. ���̿� ���̰� ���� ������ ��ҵǸ�, 0.25�� default�� �����Ͽ� �ּ��� �ۼ��Ͽ���. // ������ bit�� ���� ���̷��� 0.25���� ���� ���� ���� (bit�� �ٲ�� Rx�� �ٸ� �Ķ���͵� ����)
img = imbinarize(img);% ��ҵ� �̹����� �� �ȼ��� 1�� 0���� binarize�Ͽ� �����Ѵ�.

bits = img(:).';% binarize�� ��ģ �̹����� 1, 0 ���� bits��� �����Ϳ� ���� �����Ͽ� �����Ѵ�.

A = [ 1 1 1;1 1 0;1 0 1;0 1 1 ];%Parity submatrix-Need binary(decimal combination of 7,6,5,3)            
G = [ eye(4) A ];%Generator matrix
chan = [];
for i = 0:1023
    chan = [chan mod(bits(4*i+1:4*i+4)*G,2)];
end
bits = chan';

% Generate modulator (bit�� �������� ���ļ� ��ȣ�� �̿��Ͽ� modulate)
i = 1:16;% modulator�� �� ������ ���� �����̴�. �� ������ �����ϱ� ������ i�� ����� for���� �����Ѵ�.
t = 1:2000;% 44100�� �Բ� symbol duration�� �����Ѵ�. Ư�� ���ļ��� ���� ��ȿ�� ���� ������ �ð��� ���̸� ��Ÿ����.
tg = 1:2000;% symbol duration�� �Բ� modulator�� ���� �����Ѵ�. modulator ���� ������ ���� symbol duration �̳��� ���� ��ȿ�ϱ� ������ tg�� ���������� 0�� �����Ѵ�.
Fs = 500*i + 8000;% sampling frequency�̴�. ������ bit�� ���� �ٸ� frequency�� �ο������ν� ���� receiver �ܰ迡�� DTFT�� ���� demodulation�� �����ϵ��� �Ѵ�.
Modulator = zeros(i(end),t(end)+tg(end));% ���� 16x4000�� �迭�� modulator�� �������ش�.
for i = 1:length(i)% for ���� i�� �����Ͽ�, modulator�� ���� �Է��� �� ���� ������ ����ǵ��� �Ѵ�.
    Modulator(i,t) = sin(2*pi*t/44100*Fs(i));% ������ t�� i�� ������ ���� ���� ���ļ��� �����ϰ� �� ����� modulator �迭�� �����Ѵ�. �ռ� ���� ��ó�� symbol duration ���Ŀ��� 0���� �����ϸ�, Fs�� i�� ���� �������� �����Ƿ� �۽��ϴ� ������ bit�� ���� �������� �ο��� �� �ִ�.
end

% Create preamble (length 64)
preamble = zeros(1,16000);% 16000���� ���� ������ �� �ִ� ���� ���� �迭�� �������ش�.
tp = 1:12000;% modulator������ ���� preamble ��ȣ���� ��ȿ�� �Ⱓ�� ��Ÿ����. 16000���� data �� tp�� ���̿� �ش��ϴ� ��ŭ�� data�� ������ �������� 0�� �����Ѵ�.
for i = 1:16% modulator�� ���̰� 16�� �Ͱ� ���� ���ƿ� �ִ�. preamble�� modulator�� ������ ���ļ��� ��ø���� �����Ǳ� �����̴�.
    preamble(tp) = preamble(tp) + sin(2*pi*tp/44100*Fs(i));% 0���� ���ִ� ���� ���� ��Ŀ� preamble ��ȣ���� �Է����ش�. �ٸ� data�� ���� ���� modulator�� ������ ���ļ��� ��ȣ�� ��ø������ �׾� preamble�� Ư������ �ο��Ѵ�.
end

% Modulate bits to sinusoidal signal
Bits = reshape(bits,[16,length(bits)/16]).';% ������ �����Ͽ��� bits�� ���� ���� 16���� ������ ���� ���ο� ������ ��� Bits�� �����Ѵ�. �߰���, transpose�� ���Ѵ�.
data = [];% �迭 ������ data ���� ����
for i = 1:size(Bits,1)% Bits�� transpose�� ���Ͽ����Ƿ� �� �������� ������ ������ �� �ֵ��� �Ѵ�. ��, i�� ���� ������ ����Ѵ�.
    data = [data Bits(i,:)*Modulator];% ������ ������ Bits �迭�� �� ��� modulator�� ��İ��� ���� �� data �迭�� ������� �߰��Ѵ�. modulator�� ���̰� 16�̱� ������ 16���� bit�� modulation ������ ��ģ��. 16���� bit�� 16���� ���ļ��� ���� mapping �Ǿ� modulation ó���� ��ȣ�� �����ϴ� ���̴�.
end
x = [preamble data];% transmitter�� ��� ������ ���� ��, ������ ���� preamble ��ȣ�� ���� �տ� �����Ͽ� ������ ��ȣ�� �ϼ��Ѵ�.
x = x./max(x);% ��ȣ�� max������ ������ ������ normalize�Ѵ�.
sound(x,44100)% �� ���������� �����ϰ� sampling rate�� 44.1kHz�� ����ϰ�, normalize���� ��ģ ��ȣ�� ����Ѵ�.

%audiowrite('sound.wav',x,44100);% ��Ʈ�� �� ��� �����Ͽ��� ������ ��ȣ�� ���� ���Ϸ� �����Ͽ���.