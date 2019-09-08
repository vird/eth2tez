# eth2tez
ethereum to tezos translator

## recommended software requirements


    # install nvm https://github.com/nvm-sh/nvm 
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.34.0/install.sh | bash
    source ~/.bashrc
    # node install
    nvm i 6.6
    npm i -g iced-coffee-script
    # install this repo
    npm i -g vird/eth2tez
    # if you are root use THIS INSTEAD
    npm i -g vird/eth2tez --unsafe-perm

## how to use
# under dev

    ./eth2tez contract.sol
    ./eth2tez contract_folder
