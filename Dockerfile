FROM seleniarm/standalone-chromium:117.0

USER root

RUN apt update && apt-get install -y build-essential python3.11 python3.11-venv python3-pip libssl-dev libffi-dev python3-dev python3-tk

RUN mkdir -p /venv && python3.11 -m venv /venv

ENV PATH=/venv/bin:$PATH

RUN pip install selenium==4.4.0

RUN  apt install -y  fcitx5 fcitx5-chinese-addons locales fonts-wqy-zenhei

RUN echo "no" | dpkg-reconfigure dash \
    && echo "zh_CN.UTF-8" | dpkg-reconfigure locales
COPY app /opt/app
COPY etc/supervisor/app.conf /etc/supervisor/conf.d/app.conf
RUN chmod +x /opt/app/start.sh

HEALTHCHECK --interval=5s --timeout=5s CMD nc -z 127.0.0.1 5900 || exit 1

USER seluser

