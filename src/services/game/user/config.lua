local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
}

config.errorStr = {
    [config.code.SUCCESS] = "User Success",
    [config.code.FAILED] = "User Failed",
}

return config