import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { parseUkLoginPhone, prefersUkPhoneAuth } from "./uk-auth.ts";

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

describe("parseUkLoginPhone", () => {
  it("accepts a UK mobile", () => {
    assert.deepEqual(parseUkLoginPhone("07123 456789"), {
      status: "ok",
      phone: "+447123456789",
    });
  });

  it("flags a US number so the UI can switch to email", () => {
    assert.deepEqual(parseUkLoginPhone("+1 415 555 2671"), { status: "not_uk" });
  });

  it("rejects a UK landline-shaped number", () => {
    assert.deepEqual(parseUkLoginPhone("020 7946 0958"), { status: "invalid" });
  });
});
