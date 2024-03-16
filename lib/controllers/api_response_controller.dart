bool responseCode(int? code) {
  if (code != null) {
    if (code >= 200 && code <= 299) {
      return true;
    }
  }
  return false;
}

bool internalServerError(int? code) {
  if (code != null) {
    if (code == 500) {
      return true;
    }
  }
  return false;
}
