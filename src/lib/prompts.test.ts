import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { PROMPTS } from "./prompts.ts";

describe("prompt copy", () => {
  it("keeps stable ids so old entries still map", () => {
    const ids = PROMPTS.map((prompt) => prompt.id);
    assert.ok(ids.includes("whoWasDrunkest"));
    assert.ok(ids.includes("funniestThing"));
    assert.ok(ids.includes("tonightsObjective"));
    assert.ok(ids.includes("kissedAnyone"));
  });

  it("uses the cooler recap wording", () => {
    const byId = Object.fromEntries(PROMPTS.map((prompt) => [prompt.id, prompt.label]));
    assert.equal(byId.whoWasDrunkest, "Who was most gone");
    assert.equal(byId.funniestThing, "The funniest bit");
    assert.equal(byId.tonightsObjective, "The plan");
    assert.equal(byId.kissedAnyone, "Anyone get kissed?");
    assert.equal(byId.oneWordVibe, "One word");
    assert.equal(byId.generalComment, "Anything else");
  });
});
