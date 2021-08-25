## Use nixpkgs from environment
#import <nixpkgs>

## Use frozen nixpkgs from internet
with builtins;
fetchTarball {
 url    = "https://github.com/nixos/nixpkgs/archive/b7d9b2a9e9d26dc98e264087e31bce151adfd7f7.tar.gz";
 sha256 = "0v9m9qzfaj8w7zfdh6581xa2i5z7rsn858nhkk0acpf6z3nxl7c1";
}
