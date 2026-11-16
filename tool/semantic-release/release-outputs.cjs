// Plugin semantic-release local : relie semantic-release au workflow GitHub
// Actions (.github/workflows/release.yml), qui le lance deux fois.
//
//   1. Job `version`, en --dry-run : seules les étapes jusqu'à generateNotes
//      tournent. `verifyRelease` écrit la prochaine version dans
//      build/release/version — fichier absent = rien à publier, builds sautés.
//   2. Job `tag`, pour de vrai, une fois tous les builds verts :
//      `verifyRelease` refuse de taguer si la version recalculée diffère de
//      celle compilée dans les binaires (EXPECTED_VERSION) ; `prepare` écrit le
//      changelog dans build/release/notes.md (notes de la GitHub Release).
//      semantic-release pose ensuite le tag sur le commit buildé et le pousse
//      vers GitLab (repositoryUrl).
//
// Fichiers plutôt que @semantic-release/exec : les notes contiennent guillemets
// et backticks, qu'un template shell casserait.
const fs = require('node:fs');
const path = require('node:path');

const outDir = (cwd) => path.join(cwd, 'build', 'release');

function write(cwd, name, content) {
  fs.mkdirSync(outDir(cwd), { recursive: true });
  fs.writeFileSync(path.join(outDir(cwd), name), content);
}

module.exports = {
  verifyRelease(_pluginConfig, { cwd, env, nextRelease, logger }) {
    const expected = env.EXPECTED_VERSION;
    if (expected && expected !== nextRelease.version) {
      throw new Error(
        `Version recalculée ${nextRelease.version} ≠ version buildée ${expected} : ` +
          'on ne tague pas des binaires qui portent un autre numéro.',
      );
    }
    write(cwd, 'version', nextRelease.version);
    logger.log('Prochaine version : %s', nextRelease.version);
  },

  prepare(_pluginConfig, { cwd, nextRelease }) {
    write(cwd, 'notes.md', nextRelease.notes);
  },
};
