default: bootstrap

bootstrap: ekhos

ekhos:
    cd ekhos && zig build && zig-out/bin/ekhos-render

test:
    cd ekhos && zig build
