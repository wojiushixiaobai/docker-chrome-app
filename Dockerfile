FROM python:3.11-slim-bullseye
ARG TARGETARCH

ARG DEPENDENCIES="                    \
        ca-certificates               \
        dbus-x11                      \
        fonts-wqy-microhei            \
        gnupg2                        \
        ibus                          \
        ibus-pinyin                   \
        libffi-dev                    \
        libgbm-dev                    \
        libgl1-mesa-glx               \
        libnss3                       \
        libssl-dev                    \
        locales                       \
        mesa-utils                    \
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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
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

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    set -ex \
    && apt-get update \
    && apt install -y --no-install-recommends chromium chromium-driver

RUN --mount=type=cache,target=/root/.cache \
    set -ex \
    && python3 -m venv /opt/py3 \
    && . /opt/py3/bin/activate \
    && pip install selenium==4.4.0

WORKDIR /opt

ENV PATH=/opt/py3/bin:$PATH \
    GTK_IM_MODULE="ibus" \
    XMODIFIERS="@im=ibus" \
    QT_IM_MODULE="ibus"

COPY app /opt/app
COPY etc/supervisor/app.conf /etc/supervisor/conf.d/app.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY .config/dconf /root/.config/dconf

RUN LANG=C xdg-user-dirs-update --force

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
