import assert from "node:assert/strict";
import { buildSeedreamRequestBody } from "../src/providers/image/seedreamImageProvider.mjs";

const body = buildSeedreamRequestBody({
  prompt: [
    "生成一张纯商业摄影背景底图，不要生成成品海报设计。",
    "完整全画幅高级商品摄影构图，产品、道具、阴影、材质、空间纵深和光线自然铺满整张海报，不要大面积空白。",
    "上半画幅也必须至少有两个可识别的场景物件，不能只是一片抽象虚化，任何单一低细节墙面、窗面或桌面都不能占据画面主导面积。"
  ].join(" "),
  style: "Clean",
  aspectRatio: "3:4",
  productImageDataUrl: "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD"
});

assert.match(body.prompt, /完整全画幅/);
assert.match(body.prompt, /不要大面积空白/);
assert.doesNotMatch(body.prompt, /优先在画面上方或中部留白/);
assert.doesNotMatch(body.prompt, /优先在画面上方或中部/);
assert.doesNotMatch(body.prompt, /文案安全区/);
assert.doesNotMatch(body.prompt, /干净留白区域/);
assert.doesNotMatch(body.prompt, /大块干净留白/);
assert.match(body.prompt, /完整全画幅高级海报摄影构图/);
assert.match(body.prompt, /画面整体必须丰富但不杂乱/);
assert.match(body.prompt, /丰富但不杂乱/);
assert.match(body.prompt, /3 到 6 个与品类相关的辅助元素/);
assert.match(body.prompt, /上半画幅也必须至少有两个可识别的场景物件/);
assert.match(body.prompt, /不能只是一片抽象虚化/);
assert.match(body.prompt, /单一低细节墙面、窗面或桌面都不能占据画面主导面积/);
assert.doesNotMatch(body.prompt, /二维码/);
assert.doesNotMatch(body.prompt, /标题区/);
assert.doesNotMatch(body.prompt, /按钮/);

console.log("Poster full-frame layout prompt check passed.");
