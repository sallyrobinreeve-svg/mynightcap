import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { DEFAULT_PROMPT_IDS, PROMPTS } from "./prompts.ts";

describe("prompt copy", () => {
  it("keeps stable ids so old entries still map", () => {
    const ids = PROMPTS.map((prompt) => prompt.id);
    assert.ok(ids.includes("whoWasDrunkest"));
    assert.ok(ids.includes("funniestThing"));
    assert.ok(ids.includes("tonightsObjective"));
    assert.ok(ids.includes("kissedAnyone"));
    assert.ok(ids.includes("chaos"));
  });

  it("uses the requested recap wording", () => {
    const byId = Object.fromEntries(PROMPTS.map((prompt) => [prompt.id, prompt.label]));
    assert.equal(byId.whoWasDrunkest, "Who was the drunkest");
    assert.equal(byId.funniestThing, "The funniest bit");
    assert.equal(byId.tonightsObjective, "Mission of the night");
    assert.equal(byId.kissedAnyone, "Anyone get kissed?");
    assert.equal(byId.generalComment, "Notable mentions");
  });

  it("does not offer chaos as a create prompt", () => {
    assert.ok(!DEFAULT_PROMPT_IDS.includes("chaos"));
  });
});
