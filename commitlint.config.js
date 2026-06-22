// Conventional Commits enforcement (used by the commit-msg pre-commit hook).
module.exports = {
  extends: ['@commitlint/config-conventional'],
  rules: {
    'type-enum': [
      2,
      'always',
      ['feat', 'fix', 'perf', 'refactor', 'docs', 'test', 'build', 'ci', 'deps', 'chore', 'revert'],
    ],
    'subject-case': [0], // allow any case in the description
    'header-max-length': [2, 'always', 100],
    'body-max-line-length': [0], // allow long lines in bodies (URLs, logs)
  },
};
