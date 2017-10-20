FROM zeroc0d3lab/centos-base-workspace-lite:latest
MAINTAINER ZeroC0D3 Team <zeroc0d3.team@gmail.com>

#-----------------------------------------------------------------------------
# Set Environment
#-----------------------------------------------------------------------------
ENV VIM_VERSION=8.0.1207 \
    PATH_HOME=/home/docker \
    PATH_WORKSPACE=/home/docker/workspace

USER root
#-----------------------------------------------------------------------------
# Find Fastest Repo & Update Repo
#-----------------------------------------------------------------------------
RUN yum makecache fast \
    && yum -y update

#-----------------------------------------------------------------------------
# Install Workspace Dependency
#-----------------------------------------------------------------------------
RUN yum -y install \
      --setopt=tsflags=nodocs \
      --disableplugin=fastestmirror \
        gcc \
        gcc-c++ \
        kernel-devel \
        readline-dev \
        ncurses \
        ncurse-devel \
        lua-devel \ 
        lzo-devel \
#       vim \

#-----------------------------------------------------------------------------
# Clean Up All Cache
#-----------------------------------------------------------------------------
    && yum clean all

#-----------------------------------------------------------------------------
# Prepare Install Ruby
# -) copy .zshrc to /root
# -) copy .bashrc to /root
#-----------------------------------------------------------------------------
COPY ./rootfs/root/.zshrc /root/.zshrc
COPY ./rootfs/root/.bashrc /root/.bashrc
RUN $SHELL

#-----------------------------------------------------------------------------
# Download & Install
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
RUN cd /usr/local/src \
    && mv /usr/share/vim /usr/share/vim_old \
    && git clone https://github.com/vim/vim.git \
    && cd vim \
    && git checkout v${VIM_VERSION} \
    && cd src \
    && make autoconf \
    && ./configure \
            --prefix=/usr \
            --with-features=huge \
            --enable-rubyinterp \
            --enable-largefile \
    #       --disable-netbeans \
            --enable-pythoninterp \
    #       --with-python-config-dir=/usr/lib/python2.7/config-x86_64-linux-gnu \
            --enable-perlinterp \
            --enable-luainterp \
    #       --with-luajit \
    #       --enable-gui=auto \
    #       --enable-fail-if-missing \
    #       --with-lua-prefix=/usr/include/lua5.1 \
    #       --enable-cscope \
    && make distclean \
    && make \
    && cp config.mk.dist auto/config.mk \
    && sudo make install \
    && mkdir -p /usr/share/vim \
    && mkdir -p /usr/share/vim/vim80/ \
    && cp -fr ../runtime/* /usr/share/vim/vim80/

RUN git clone https://github.com/zeroc0d3/vim-ide.git $HOME/vim-ide \
    && sudo /bin/sh $HOME/vim-ide/step02.sh

RUN git clone https://github.com/dracula/vim.git /opt/vim-themes/dracula \
    && git clone https://github.com/blueshirts/darcula.git /opt/vim-themes/darcula \
    && mkdir -p $HOME/.vim/bundle/vim-colors/colors \
    && cp /opt/vim-themes/dracula/colors/dracula.vim $HOME/.vim/bundle/vim-colors/colors/dracula.vim \
    && cp /opt/vim-themes/darcula/colors/darcula.vim $HOME/.vim/bundle/vim-colors/colors/darcula.vim

#-----------------------------------------------------------------------------
# Set Configuration
#-----------------------------------------------------------------------------
COPY rootfs/ /

#-----------------------------------------------------------------------------
# Create Workspace Application Folder
#-----------------------------------------------------------------------------
RUN mkdir -p ${PATH_WORKSPACE}

#-----------------------------------------------------------------------------
# Fixing ownership for 'docker' user
#-----------------------------------------------------------------------------
RUN chown -R docker:docker ${PATH_HOME}

#-----------------------------------------------------------------------------
# Set Volume Docker Workspace
#-----------------------------------------------------------------------------
VOLUME [${PATH_WORKSPACE}]

#-----------------------------------------------------------------------------
# Run Init Docker Container
#-----------------------------------------------------------------------------
ENTRYPOINT ["/init"]
CMD []

## NOTE:
## *) Run vim then >> :PluginInstall
## *) Update plugin vim (vundle) >> :PluginUpdate
## *) Run in terminal >> vim +PluginInstall +q
##                       vim +PluginUpdate +q
