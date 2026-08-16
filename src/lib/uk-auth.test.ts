import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { prefersUkPhoneAuth } from "./uk-auth.ts";

describe("prefersUkPhoneAuth", () => {
  it("treats British English and London time as UK", () => {
    assert.equal(
      prefersUkPhoneAuth({ languages: ["en-GB"], timeZone: "America/New_York" }),
      true
    );
    assert.equal(
      prefersUkPhoneAuth({ languages: ["en-US"], timeZone: "Europe/London" }),
      true
    );
  });

  it("directs US locale to email", () => {
    assert.equal(
      prefersUkPhoneAuth({ languages: ["en-US"], timeZone: "America/New_York" }),
      false
    );
  });
});
