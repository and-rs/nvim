default: bootstrap

bootstrap: zetesis ekhos

zetesis:
    cd zetesis && zig build

ekhos:
    cd ekhos && zig build

test:
    cd zetesis && zig build test
    cd ekhos && zig build
