FROM zeroc0d3lab/centos-base-workspace-lite:latest
MAINTAINER ZeroC0D3 Team <zeroc0d3.team@gmail.com>

#-----------------------------------------------------------------------------
# Set Environment
#-----------------------------------------------------------------------------
ENV VIM_VERSION=8.0.1207 \
    LUA_VERSION=5.3.4 \
    LUAROCKS_VERSION=2.4.3 \
    PATH_HOME=/home/docker \
    PATH_WORKSPACE=/home/docker/workspace

USER root
#-----------------------------------------------------------------------------
# Find Fastest Repo & Update Repo
#-----------------------------------------------------------------------------
RUN curl -L https://copr.fedorainfracloud.org/coprs/mcepl/vim8/repo/epel-7/mcepl-vim8-epel-7.repo \
      -o /etc/yum.repos.d/mcepl-vim8-epel-7.repo

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
        vim* \

#-----------------------------------------------------------------------------
# Clean Up All Cache
#-----------------------------------------------------------------------------
    && yum clean all

#-----------------------------------------------------------------------------
# Prepare Install Ruby
# -) copy .zshrc to /root
# -) copy .bashrc to /root
# -) copy installation scripts to /opt
#-----------------------------------------------------------------------------
COPY ./rootfs/root/.zshrc /root/.zshrc
COPY ./rootfs/root/.bashrc /root/.bashrc
COPY ./rootfs/opt/ruby.sh /etc/profile.d/ruby.sh
COPY ./rootfs/opt/install_ruby.sh /opt/install_ruby.sh
COPY ./rootfs/opt/reload_shell.sh /opt/reload_shell.sh
# RUN sudo /bin/sh /opt/install_ruby.sh

#-----------------------------------------------------------------------------
# Copy package dependencies in Gemfile
#-----------------------------------------------------------------------------
COPY ./rootfs/root/Gemfile /opt/Gemfile
COPY ./rootfs/root/Gemfile.lock /opt/Gemfile.lock

#-----------------------------------------------------------------------------
# Install Ruby Packages (rbenv/rvm)
#-----------------------------------------------------------------------------
COPY ./rootfs/root/gems.sh /opt/gems.sh
# RUN sudo /bin/sh /opt/gems.sh

#-----------------------------------------------------------------------------
# Download & Install
# -) lua
# -) luarocks
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
COPY ./rootfs/opt/install_vim.sh /opt/install_vim.sh
# RUN sudo /bin/sh /opt/install_vim.sh

#-----------------------------------------------------------------------------
# Install Lua
#-----------------------------------------------------------------------------
RUN curl -L http://www.lua.org/ftp/lua-${LUA_VERSION}.tar.gz -o /opt/lua-${LUA_VERSION}.tar.gz \
    && curl -L http://luarocks.github.io/luarocks/releases/luarocks-${LUAROCKS_VERSION}.tar.gz \
         -o /opt/luarocks-${LUAROCKS_VERSION}.tar.gz

RUN cd /opt \
    && tar zxvf lua-${LUA_VERSION}.tar.gz \
    && tar zxvf luarocks-${LUAROCKS_VERSION}.tar.gz \
    && cd lua-${LUA_VERSION} \
    && make linux \
    && cd ../luarocks-${LUAROCKS_VERSION} \
    && ./configure \
    && make \
    && sudo make install

#-----------------------------------------------------------------------------
# Download & Install
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
RUN rm -rf /root/vim \
    && git clone https://github.com/vim/vim.git /root/vim \
    && cd /root/vim \
    && git checkout v${VIM_VERSION} \
    && cd src \
    && make autoconf \
    && ./configure \
    && make distclean \
    && make \
    && cp config.mk.dist auto/config.mk \
    && sudo make install \
    && sudo mkdir -p /usr/share/vim \
    && sudo mkdir -p /usr/share/vim/vim80/ \
    && sudo cp -fr /root/vim/runtime/** /usr/share/vim/vim80/

RUN git clone https://github.com/zeroc0d3/vim-ide.git /root/vim-ide \
    && sudo /bin/sh /root/vim-ide/step02.sh

RUN git clone https://github.com/dracula/vim.git /opt/vim-themes/dracula \
    && git clone https://github.com/blueshirts/darcula.git /opt/vim-themes/darcula \
    && mkdir -p /root/.vim/bundle/vim-colors/colors \
    && cp /opt/vim-themes/dracula/colors/dracula.vim /root/.vim/bundle/vim-colors/colors/dracula.vim \
    && cp /opt/vim-themes/darcula/colors/darcula.vim /root/.vim/bundle/vim-colors/colors/darcula.vim

RUN tar zcvf vim.tar.gz /root/vim /root/.vim \
    && mv vim.tar.gz /opt

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
