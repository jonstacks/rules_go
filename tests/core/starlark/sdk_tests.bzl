load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//go/private:extensions.bzl", "default_go_sdk_name")
load("//go/private:sdk.bzl", "go_toolchains_single_definition")

def _go_toolchains_single_definition_with_version_test(ctx):
    env = unittest.begin(ctx)

    result = go_toolchains_single_definition(
        ctx = None,
        prefix = "123_prefix_",
        goos = "linux",
        goarch = "amd64",
        sdk_repo = "sdk_repo",
        sdk_type = "download",
        sdk_version = "1.20.2rc1",
    )
    asserts.equals(env, [], result.loads)
    asserts.equals(env, [
        """
_123_PREFIX_MAJOR_VERSION = "1"
_123_PREFIX_MINOR_VERSION = "20"
_123_PREFIX_PATCH_VERSION = "2"
_123_PREFIX_PRERELEASE_SUFFIX = "rc1"
""",
        """declare_bazel_toolchains(
    prefix = "123_prefix_",
    go_toolchain_repo = "@sdk_repo",
    exec_goarch = "amd64",
    exec_goos = "linux",
    major = _123_PREFIX_MAJOR_VERSION,
    minor = _123_PREFIX_MINOR_VERSION,
    patch = _123_PREFIX_PATCH_VERSION,
    prerelease = _123_PREFIX_PRERELEASE_SUFFIX,
    sdk_name = "sdk_repo",
    sdk_type = "download",
)
""",
    ], result.chunks)

    return unittest.end(env)

go_toolchains_single_definition_with_version_test = unittest.make(_go_toolchains_single_definition_with_version_test)

def _go_toolchains_single_definition_without_version_test(ctx):
    env = unittest.begin(ctx)

    result = go_toolchains_single_definition(
        ctx = None,
        prefix = "123_prefix_",
        goos = "linux",
        goarch = "amd64",
        sdk_repo = "sdk_repo",
        sdk_type = "download",
        sdk_version = None,
    )
    asserts.equals(env, ["""load(
    "@sdk_repo//:version.bzl",
    _123_PREFIX_MAJOR_VERSION = "MAJOR_VERSION",
    _123_PREFIX_MINOR_VERSION = "MINOR_VERSION",
    _123_PREFIX_PATCH_VERSION = "PATCH_VERSION",
    _123_PREFIX_PRERELEASE_SUFFIX = "PRERELEASE_SUFFIX",
)
"""], result.loads)
    asserts.equals(env, [
        """declare_bazel_toolchains(
    prefix = "123_prefix_",
    go_toolchain_repo = "@sdk_repo",
    exec_goarch = "amd64",
    exec_goos = "linux",
    major = _123_PREFIX_MAJOR_VERSION,
    minor = _123_PREFIX_MINOR_VERSION,
    patch = _123_PREFIX_PATCH_VERSION,
    prerelease = _123_PREFIX_PRERELEASE_SUFFIX,
    sdk_name = "sdk_repo",
    sdk_type = "download",
)
""",
    ], result.chunks)

    return unittest.end(env)

go_toolchains_single_definition_without_version_test = unittest.make(_go_toolchains_single_definition_without_version_test)

def _default_go_sdk_name_with_sdk_version_test(ctx):
    """Test that SDK version is included in the default name when specified."""
    env = unittest.begin(ctx)

    module = struct(is_root = True, version = "1.0.0", name = "root")
    result = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.25.5",
    )
    asserts.equals(env, "main___download_0_1_25_5", result)

    return unittest.end(env)

default_go_sdk_name_with_sdk_version_test = unittest.make(_default_go_sdk_name_with_sdk_version_test)

def _default_go_sdk_name_without_sdk_version_test(ctx):
    """Test that SDK name is unchanged when sdk_version is empty."""
    env = unittest.begin(ctx)

    module = struct(is_root = True, version = "1.0.0", name = "root")
    result = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
    )
    asserts.equals(env, "main___download_0", result)

    return unittest.end(env)

default_go_sdk_name_without_sdk_version_test = unittest.make(_default_go_sdk_name_without_sdk_version_test)

def _default_go_sdk_name_version_change_produces_different_name_test(ctx):
    """Test that changing the SDK version produces a different repo name.

    This is the core fix for https://github.com/bazel-contrib/rules_go/issues/4536:
    when the Go version changes (e.g. via from_file reading a different go.mod),
    the SDK repo name must change so that dependent repos are re-fetched.
    """
    env = unittest.begin(ctx)

    module = struct(is_root = True, version = "1.0.0", name = "root")
    name_v1 = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.25.4",
    )
    name_v2 = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.25.5",
    )
    asserts.true(env, name_v1 != name_v2, "SDK names must differ when versions differ: {} vs {}".format(name_v1, name_v2))
    asserts.equals(env, "main___download_0_1_25_4", name_v1)
    asserts.equals(env, "main___download_0_1_25_5", name_v2)

    return unittest.end(env)

default_go_sdk_name_version_change_produces_different_name_test = unittest.make(_default_go_sdk_name_version_change_produces_different_name_test)

def _default_go_sdk_name_with_sdk_version_and_platform_suffix_test(ctx):
    """Test that SDK version and platform suffix are both included."""
    env = unittest.begin(ctx)

    module = struct(is_root = True, version = "1.0.0", name = "root")
    result = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.25.5",
        suffix = "_linux_amd64",
    )
    asserts.equals(env, "main___download_0_1_25_5_linux_amd64", result)

    return unittest.end(env)

default_go_sdk_name_with_sdk_version_and_platform_suffix_test = unittest.make(_default_go_sdk_name_with_sdk_version_and_platform_suffix_test)

def _default_go_sdk_name_non_root_module_test(ctx):
    """Test SDK naming for non-root modules includes SDK version."""
    env = unittest.begin(ctx)

    module = struct(is_root = False, version = "2.0.0", name = "my_module")
    result = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.22.0",
    )
    asserts.equals(env, "my_module__download_0_1_22_0", result)

    return unittest.end(env)

default_go_sdk_name_non_root_module_test = unittest.make(_default_go_sdk_name_non_root_module_test)

def _default_go_sdk_name_prerelease_version_test(ctx):
    """Test SDK naming with pre-release version string."""
    env = unittest.begin(ctx)

    module = struct(is_root = True, version = "1.0.0", name = "root")
    result = default_go_sdk_name(
        module = module,
        multi_version = False,
        tag_type = "download",
        index = 0,
        sdk_version = "1.25rc1",
    )
    asserts.equals(env, "main___download_0_1_25rc1", result)

    return unittest.end(env)

default_go_sdk_name_prerelease_version_test = unittest.make(_default_go_sdk_name_prerelease_version_test)

def sdk_test_suite():
    unittest.suite(
        "sdk_tests",
        go_toolchains_single_definition_with_version_test,
        go_toolchains_single_definition_without_version_test,
        default_go_sdk_name_with_sdk_version_test,
        default_go_sdk_name_without_sdk_version_test,
        default_go_sdk_name_version_change_produces_different_name_test,
        default_go_sdk_name_with_sdk_version_and_platform_suffix_test,
        default_go_sdk_name_non_root_module_test,
        default_go_sdk_name_prerelease_version_test,
    )
