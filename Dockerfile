FROM python:3.11-slim-bullseye
ARG TARGETARCH

ARG DEPENDENCIES="                    \
        ca-certificates               \
        dbus-x11                      \
        fonts-wqy-zenhei              \
        fonts-wqy-microhei            \
        gnupg2                        \
        ibus                          \
        ibus-pinyin                   \
        libffi-dev                    \
        libgbm-dev                    \
        libnss3                       \
        libssl-dev                    \
        locales                       \
        netcat-openbsd                \
        pulseaudio                    \
        supervisor                    \
        unzip                         \
        wget                          \
        x11vnc                        \
        xauth                         \
        xdg-user-dirs                 \
        xvfb"

ARG APT_MIRROR=http://mirrors.ustc.edu.cn

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=app-apt \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=app-apt \
    sed -i "s@http://.*.debian.org@${APT_MIRROR}@g" /etc/apt/sources.list \
    && rm -f /etc/apt/apt.conf.d/docker-clean \
    && ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && apt-get update \
    && apt-get install -y --no-install-recommends ${DEPENDENCIES} \
    && echo "no" | dpkg-reconfigure dash \
    && echo "zh_CN.UTF-8" | dpkg-reconfigure locales \
    && sed -i "s@# export @export @g" ~/.bashrc \
    && sed -i "s@# alias @alias @g" ~/.bashrc \
    && chmod +x /dev/shm \
    && mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix

ARG CHROME_VERSION="google-chrome-stable"
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked,id=app-apt \
    --mount=type=cache,target=/var/lib/apt,sharing=locked,id=app-apt \
    wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb https://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update -qqy \
    && apt-get -qqy install --no-install-recommends \
    ${CHROME_VERSION:-google-chrome-stable} \
    && rm /etc/apt/sources.list.d/google-chrome.list \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG CHROME_DRIVER_VERSION
RUN if [ ! -z "$CHROME_DRIVER_VERSION" ]; \
    then CHROME_DRIVER_URL=https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$CHROME_DRIVER_VERSION/linux64/chromedriver-linux64.zip ; \
    else echo "Geting ChromeDriver latest version from https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_" \
    && CHROME_MAJOR_VERSION=$(google-chrome --version | sed -E "s/.* ([0-9]+)(\.[0-9]+){3}.*/\1/") \
    && CHROME_DRIVER_VERSION=$(wget -qO- https://googlechromelabs.github.io/chrome-for-testing/LATEST_RELEASE_${CHROME_MAJOR_VERSION} | sed 's/\r$//') \
    && CHROME_DRIVER_URL=https://edgedl.me.gvt1.com/edgedl/chrome/chrome-for-testing/$CHROME_DRIVER_VERSION/linux64/chromedriver-linux64.zip ; \
    fi \
    && echo "Using ChromeDriver from: "$CHROME_DRIVER_URL \
    && echo "Using ChromeDriver version: "$CHROME_DRIVER_VERSION \
    && wget --no-verbose -O /tmp/chromedriver_linux64.zip $CHROME_DRIVER_URL \
    && rm -rf /opt/selenium/chromedriver \
    && unzip /tmp/chromedriver_linux64.zip -d /opt/selenium \
    && rm /tmp/chromedriver_linux64.zip \
    && mv /opt/selenium/chromedriver-linux64/chromedriver /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
    && chmod 755 /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION \
    && ln -fs /opt/selenium/chromedriver-$CHROME_DRIVER_VERSION /usr/bin/chromedriver

RUN --mount=type=cache,target=/root/.cache \
    set -ex \
    && python3 -m venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && pip install selenium==4.4.0

WORKDIR /opt

ENV PATH=/opt/py3/bin:$PATH

COPY app /opt/app
COPY etc/supervisor/app.conf /etc/supervisor/conf.d/app.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

RUN LANG=C xdg-user-dirs-update --force

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
