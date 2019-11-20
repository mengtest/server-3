local config = {}

config.code = {
    SUCCESS = 1,
    FAILED = 2,
}

config.errorStr = {
    [config.code.SUCCESS] = "Success",
    [config.code.FAILED] = "Failed",
}

config.offlineCode = {
    TIMEOUT = 1,
    BAN = 2,
}

config.offlineErrorStr = {
    [config.offlineCode.TIMEOUT] = "Time Out",
    [config.offlineCode.BAN] = "Ban"
}

return config