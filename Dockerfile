FROM python:3-buster

ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/src/app/bin

# Make stdout/stderr unbuffered. This prevents delay between output and cloud.
# Might not be needed by all apps, but slow ALL of them. test per app/container
#ENV PYTHONUNBUFFERED "1"

### To prevent the Debian installer from freaking out on configuration of packages
ENV DEBIAN_FRONTEND noninteractive

# Pinned versions of few oddball dependencies
ENV SASQUATCH_COMMIT 3e0cc40fc6dbe32bd3a5e6c553b3320d5d91ceed
ENV UBIREADER_COMMIT 0955e6b95f07d849a182125919a1f2b6790d5b51
ENV BINWALK_COMMIT   3154b0012e7dbaf2b20edd5c0a2350ec64009869

COPY . /tmp

WORKDIR /tmp

### Took out the deps.sh from binwalk's installation script, baked in the dependencies into the main prereqs installation
### The prereqs that dont come from system's repo, are taken care of later
RUN set -xue \
    && apt-get update -qy \
    && apt-get -t buster dist-upgrade -yq --no-install-recommends -o Dpkg::Options::="--force-confold" \
    && ./deps.sh --yes \
    && python3 setup.py install && binwalk -h > /dev/null \
    && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen \
    && echo "LANG=en_US.UTF-8" >> /etc/default/locale \
    && echo "LANGUAGE=en_US:en" >> /etc/default/locale \
    && echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale \
    && locale-gen \
    && apt-get -y autoremove \
    && apt-get -y autoclean \
    && useradd -m -u 1000 -s /sbin/nologin appuser \
    && rm -rf -- \
        /var/lib/apt/lists/* \
        /tmp/* /var/tmp/* \
        /usr/src/app/*.whl /usr/src/app/*.tar.gz \
        /root/.cache/pip \
        /usr/src/app/repos \
        /usr/src/app/.git \
        /usr/src/app/src


ENV DEBIAN_FRONTEND teletype
# Setup locale. This prevents Python 3 IO encoding issues.
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8
ENV PYTHONUTF8 "1"
ENV PYTHONHASHSEED "random"

WORKDIR /home/appuser
USER appuser

# dummy run because it creates some files on first run in home dir
RUN binwalk -h > /dev/null

ENTRYPOINT ["binwalk"]
