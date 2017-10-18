FROM zeroc0d3lab/centos-base-workspace-lite:latest
MAINTAINER ZeroC0D3 Team <zeroc0d3.team@gmail.com>

#-----------------------------------------------------------------------------
# Set Environment
#-----------------------------------------------------------------------------
ENV VIM_VERSION=8.0.1203 \
    PATH_HOME=/home/docker \
    PATH_WORKSPACE=/home/docker/workspace

#-----------------------------------------------------------------------------
# Download & Install
# -) vim
# -) vundle + themes
#-----------------------------------------------------------------------------
RUN curl -sSL https://github.com/vim/vim/archive/v${VIM_VERSION}.zip -o $HOME/vim.zip \
    && cd $HOME \
    && unzip $HOME/vim.zip \
    && mv $HOME/vim-${VIM_VERSION} $HOME/vim

RUN cd $HOME/vim/src \
    && /bin/sh ./configure \
    && sudo make \
    && sudo make install \
    && sudo mkdir /usr/share/vim \
    && sudo mkdir /usr/share/vim/vim80/ \
    && sudo cp -fr $HOME/vim/runtime/* /usr/share/vim/vim80/

RUN git clone https://github.com/zeroc0d3/vim-ide.git $HOME/vim-ide \
    && sudo /bin/sh $HOME/vim-ide/step02.sh

RUN git clone https://github.com/dracula/vim.git /opt/vim-themes/dracula \
    && git clone https://github.com/blueshirts/darcula.git /opt/vim-themes/darcula \
    && mkdir -p $HOME/.vim/bundle/vim-colors/colors \
    && sudo cp /opt/vim-themes/dracula/colors/dracula.vim $HOME/.vim/bundle/vim-colors/colors/dracula.vim \
    && sudo cp /opt/vim-themes/darcula/colors/darcula.vim $HOME/.vim/bundle/vim-colors/colors/darcula.vim

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