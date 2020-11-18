package bake

command: {
  image: #Dubo & {
    args: {
      BUILD_TITLE: "Apt cacher"
      BUILD_DESCRIPTION: "A dubo image for aptutil based on \(args.DEBOOTSTRAP_SUITE) (\(args.DEBOOTSTRAP_DATE))"
    }
  }
}
