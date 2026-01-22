.pragma library

function insertAt(original, insertion, target) {
    if (original === undefined || original === null) {
        original = "";
    }
    if (insertion === undefined || insertion === null) {
        insertion = "";
    }

    var pos = parseInt(target, 10);
    if (isNaN(pos)) {
        pos = original.length;
    }
    if (pos < 0) {
        pos = original.length + pos;
    }
    if (pos < 0) {
        pos = 0;
    } else if (pos > original.length) {
        pos = original.length;
    }

    return original.slice(0, pos) + insertion + original.slice(pos);
}

function leftPad(str, length, pad) {
    str = String(str);

    if (str.length >= length) {
        return str;
    }

    var needed = length - str.length;
    var result = '';

    while (result.length < needed) {
      result += pad;
    }

    // trim if overshoots (e.g. multi-char pad)
    if (result.length > needed) {
      result = result.slice(0, needed);
    }

    return result + str;
  }

