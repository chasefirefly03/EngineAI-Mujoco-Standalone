#include <csignal>
#include <cstdlib>
#include <cstring>
#include <exception>
#include <filesystem>
#include <map>
#include <string>
#include <vector>

#if defined(__unix__) || defined(__APPLE__)
#include <unistd.h>
#endif

#include "app/app.h"
#include "glog/logging.h"

#ifdef ENGINEAI_WITH_CRASHPAD
#include "client/crashpad_client.h"
#endif

namespace {

bool CrashpadHandlerUsable(const std::filesystem::path& path) {
  std::error_code ec;
  if (!std::filesystem::exists(path, ec)) {
    return false;
  }
#if defined(__unix__) || defined(__APPLE__)
  return access(path.c_str(), X_OK) == 0;
#else
  return true;
#endif
}

#ifdef ENGINEAI_WITH_CRASHPAD
std::filesystem::path ResolveCrashpadHandlerPath() {
  if (const char* env_path = std::getenv("ENGINEAI_CRASHPAD_HANDLER")) {
    if (env_path[0] != '\0') {
      return std::filesystem::path(env_path);
    }
  }
  if (const char* root = std::getenv("ENGINEAI_ROBOTICS_DIR")) {
    if (root[0] != '\0') {
      auto bundled =
          std::filesystem::path(root) / "deps/engineai_robotics_third_party/bin/handler";
      if (CrashpadHandlerUsable(bundled)) {
        return bundled;
      }
    }
  }
  return std::filesystem::path("/opt/engineai_robotics_third_party/bin/handler");
}
#endif

bool InitializeCrashpad() {
#ifdef ENGINEAI_WITH_CRASHPAD
  if (const char* skip = std::getenv("ENGINEAI_SKIP_CRASHPAD")) {
    if (skip[0] != '\0' && std::strcmp(skip, "0") != 0) {
      LOG(WARNING) << "ENGINEAI_SKIP_CRASHPAD is set; Crashpad disabled.";
      return true;
    }
  }

  std::filesystem::path handler_fs = ResolveCrashpadHandlerPath();
  if (!CrashpadHandlerUsable(handler_fs)) {
    LOG(WARNING) << "Crashpad handler missing or not executable (tried " << handler_fs.string()
                 << "); continuing without crash reporting. Set ENGINEAI_CRASHPAD_HANDLER or fix "
                    "permissions on deps/engineai_robotics_third_party/bin/handler.";
    return true;
  }

  std::filesystem::path coredump_dir = std::filesystem::temp_directory_path() / "crashpad" / "coredump";
  try {
    std::filesystem::create_directories(coredump_dir);
  } catch (const std::filesystem::filesystem_error& e) {
    LOG(ERROR) << "Failed to create coredump directory: " << e.what();
    return false;
  }

  base::FilePath db = base::FilePath(coredump_dir.c_str());
  base::FilePath metrics = db;
  base::FilePath handler = base::FilePath(handler_fs.string());
  std::string url = "";

  std::map<std::string, std::string> annotations;
  annotations["prod"] = "engineai_robotics";
  annotations["ver"] = "1.0.0";

  std::vector<std::string> arguments;
  // upload crash report immediately
  arguments.push_back("--no-rate-limit");

  crashpad::CrashpadClient client;
  return client.StartHandler(handler, db, metrics, url, annotations, arguments, true, false);
#else
  return true;
#endif
}

}  // namespace

int main(int argc, char* argv[]) {
  InitializeCrashpad();
  engineai_robotics::App app;

  try {
    app.RegisterApps();
    app.RunMain(argc, argv);
  } catch (const std::exception& e) {
    LOG(ERROR) << "Catch Exception: " << e.what();
    app.GracefulExit(SIGINT);
  }

  return 0;
}
