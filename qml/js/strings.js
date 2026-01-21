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
