import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { isPromptMetadataKey, isPromptPrivate } from "./prompt-privacy.ts";

describe("prompt privacy", () => {
  it("treats kiss privacy as shared across kiss fields", () => {
    const prompts = { kissedAnyone: true, kissedPrivate: true };
    assert.equal(isPromptPrivate(prompts, "kissedAnyone"), true);
    assert.equal(isPromptPrivate(prompts, "kissedWho"), true);
  });

  it("uses a per-prompt private flag for recap answers", () => {
    const prompts = { whoWasDrunkest: "Sam", whoWasDrunkestPrivate: true };
    assert.equal(isPromptPrivate(prompts, "whoWasDrunkest"), true);
    assert.equal(isPromptPrivate(prompts, "funniestThing"), false);
  });

  it("hides privacy metadata keys from prompt display", () => {
    assert.equal(isPromptMetadataKey("whoWasDrunkestPrivate"), true);
    assert.equal(isPromptMetadataKey("kissedPrivate"), true);
    assert.equal(isPromptMetadataKey("whoWasDrunkest"), false);
  });
});
