/// Data directory configuration

///|
/// Get data directory from environment or config file
/// Priority: MOONBIT_DATA_DIR env > config.json > default "data"
pub fn get_data_dir() -> String {
  // First, try environment variable
  match @ffi.getenv("MOONBIT_DATA_DIR") {
    Some(dir) => {
      println("Using data directory from MOONBIT_DATA_DIR: \{dir}")
      dir
    }
    None =>
      // Second, try to read from config.json
      match @ffi.get_project_root() {
        Some(root) => {
          let config_path = root + "/config.json"
          match @ffi.read_file(config_path) {
            Some(content) =>
              // Simple JSON parsing: look for "data_dir": "value"
              match _parse_data_dir_from_json(content) {
                Some(dir) => {
                  println("Using data directory from config.json: \{dir}")
                  // If data_dir is relative, make it absolute relative to project root
                  if dir.has_prefix("/") || dir.has_suffix(":") {
                    // Absolute path
                    dir
                  } else {
                    // Relative path, resolve relative to project root
                    root + "/" + dir
                  }
                }
                None => {
                  println("Using default data directory: data")
                  // Default "data" is relative to project root
                  root + "/data"
                }
              }
            None => {
              println(
                "Config file not found, using default data directory: data",
              )
              // Default "data" is relative to project root
              root + "/data"
            }
          }
        }
        None => {
          println(
            "Could not determine project root, using default data directory: data",
          )
          "data"
        }
      }
  }
}

///|
/// Simple JSON parser to extract data_dir field
/// Looks for pattern: "data_dir": "value" or "data_dir":"value"
fn _parse_data_dir_from_json(json : String) -> String? {
  let target = "\"data_dir\""
  match json.find(target) {
    Some(pos) => {
      // Find the colon after "data_dir"
      let after_key = json[pos + target.length():]
      let colon_pos = after_key.find(":")
      if colon_pos == None {
        return None
      }
      let after_colon = after_key[colon_pos.unwrap() + 1:]

      // Skip whitespace and find the opening quote
      let trimmed = after_colon.trim()
      if !trimmed.has_prefix("\"") {
        return None
      }

      // Find the closing quote
      let value_start = 1 // Skip opening quote
      let value_part = trimmed[value_start:]
      match value_part.find("\"") {
        Some(end_pos) => Some(value_part[:end_pos].to_string())
        None => None
      }
    }
    None => None
  }
}
