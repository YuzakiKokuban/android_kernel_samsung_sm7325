cmd_vmlinux := sh scripts/link-vmlinux.sh ld  -EL -z noexecstack  --no-undefined -X --pic-veneer --build-id ;  true
