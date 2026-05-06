import assert from "node:assert/strict";
import { buildSeedreamRequestBody, hasReferenceImage } from "../src/providers/image/seedreamImageProvider.mjs";

const referenceImage = "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD";

const bodyWithReference = buildSeedreamRequestBody({
  prompt: "Generate a clean product scene.",
  style: "Clean",
  aspectRatio: "9:16",
  productImageDataUrl: referenceImage,
  modelRoute: {
    imageModel: "doubao-seedream-4-5-251128"
  }
});

assert.equal(hasReferenceImage({ productImageDataUrl: referenceImage }), true);
assert.equal(bodyWithReference.image, referenceImage);
assert.equal(bodyWithReference.watermark, false);
assert.equal(bodyWithReference.response_format, "url");
assert.match(bodyWithReference.prompt, /真实产品/);
assert.match(bodyWithReference.prompt, /透明窗口、可见内部结构/);
assert.match(bodyWithReference.prompt, /不要复刻输入图里的背景、水印、非产品文字/);
assert.match(bodyWithReference.prompt, /只允许保留输入产品本体上物理印刷的可见标识/);

const bodyWithoutReference = buildSeedreamRequestBody({
  prompt: "Generate a clean product scene.",
  style: "Clean",
  aspectRatio: "1:1"
});

assert.equal(hasReferenceImage({}), false);
assert.equal(bodyWithoutReference.image, undefined);

console.log("Seedream reference image payload check passed.");
