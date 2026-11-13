import { test } from 'node:test';
import assert from 'node:assert/strict';
import { clockText } from '../clock.js';

const friday = new Date(2026, 10, 13, 14, 52);

test('the clock reads like the macOS menu bar, in the visitor\'s format', () => {
  assert.equal(clockText(friday, 'en-GB'), 'Fri 13 Nov 14:52');
  assert.equal(clockText(friday, 'en-US'), 'Fri Nov 13 2:52 PM');
});

test('the clock has no commas and only plain spaces', () => {
  for (const locale of ['en-GB', 'en-US', 'de-DE', 'fr-FR']) {
    assert.doesNotMatch(clockText(friday, locale), /,|[^\S ]/, locale);
  }
});
