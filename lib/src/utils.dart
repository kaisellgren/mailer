// RegExp created using:
// https://mothereff.in/regexpu
// `string.match(/^[^\p{Cc}\p{Cf}\p{Zl}\p{Zp}]*$/u);`
// as suggested by: https://stackoverflow.com/questions/12052825/regular-expression-for-all-printable-characters-in-javascript
final isPrintableRegExp = RegExp(
    r'^(?:[ -~\xA0-\xAC\xAE-\u05FF\u0606-\u061B\u061D-\u06DC\u06DE-\u070E\u0710-\u08E1\u08E3-\u180D\u180F-\u200A\u2010-\u2027\u202F-\u205F\u2065\u2070-\uD7FF\uE000-\uFEFE\uFF00-\uFFF8\uFFFC-\uFFFF]|[\uD800-\uD803\uD805-\uD82E\uD830-\uD833\uD835-\uDB3F\uDB41-\uDBFF][\uDC00-\uDFFF]|\uD804[\uDC00-\uDCBC\uDCBE-\uDCCC\uDCCE-\uDFFF]|\uD82F[\uDC00-\uDC9F\uDCA4-\uDFFF]|\uD834[\uDC00-\uDD72\uDD7B-\uDFFF]|\uDB40[\uDC00\uDC02-\uDC1F\uDC80-\uDFFF]|[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF])*$');
