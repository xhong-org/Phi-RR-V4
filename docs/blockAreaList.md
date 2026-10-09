# blockAreaList 说明

下面按这个顺序写：整份谱面里有什么、画面按 1920×1080 怎么量、`blockAreaList` 的每个字段、几条比较个别的特性、缓动编号和对应的 JavaScript。

## 1. 谱面结构

官方谱面是一个 JSON 对象。根上常见这四块：

```json
{
  "formatVersion": 3,
  "offset": 0,
  "judgeLineList": [],
  "blockAreaList": []
}
```

| 字段 | 作用 |
| --- | --- |
| `formatVersion` | 谱面版本。常见是 `1` 或 `3`。判定线移动事件的打包方式随版本不同。噪域这套字段按秒和屏幕百分比来写，不跟这个版本换算。 |
| `offset` | 秒。用来把音乐和谱面时间对齐。它移动的是整首曲子的零点，不要再加进噪域的四个时间。 |
| `judgeLineList` | 判定线数组。音符、速度、线的移动旋转透明度都在这里。 |
| `blockAreaList` | 噪域数组。没有这个字段，就表示整张谱没有噪域。别名只认 `block_area`。 |

一条判定线大致是：

| 字段 | 作用 |
| --- | --- |
| `bpm` | 这条线的 BPM。用来把线上的时间和音符时间换成秒。 |
| `judgeLineMoveEvents` | 线怎么移动。 |
| `judgeLineRotateEvents` | 线怎么旋转，单位是度。 |
| `judgeLineDisappearEvents` | 线的透明度。`0` 是完全看不见，`1` 是完全看见。 |
| `speedEvents` | 音符沿这条线下落的速度倍率。 |
| `notesAbove` | 从线的上方过来的音符。 |
| `notesBelow` | 从线的下方过来的音符。 |

线上这三种事件的一项长这样：

```json
{ "startTime": 0, "endTime": 32, "start": 0.5, "end": 0.5, "start2": 0.5, "end2": 0.5 }
```

`startTime`、`endTime` 和音符的 `time` 用同一把尺子，还不是秒。换成秒要乘 `60 / bpm / 32`。`formatVersion` 为 3 时，移动事件的 `start` / `end` 是横轴，`start2` / `end2` 是纵轴，取值大约在 0 到 1，0.5 是该方向的中心。旋转事件用 `start` / `end` 表示角度。透明度事件用 `start` / `end` 表示不透明度。

速度事件是：

```json
{ "startTime": 0, "endTime": 999999, "value": 1 }
```

`value` 是这段时间里的速度倍率。`1` 是原速，负数会让音符往反方向走。

一个音符是：

```json
{ "type": 1, "time": 128, "positionX": 0, "holdTime": 0, "speed": 1, "floorPosition": 0 }
```

| 字段 | 作用 |
| --- | --- |
| `type` | `1` 点击，`2` 拖动，`3` 长按，`4` 滑动。 |
| `time` | 打击时刻。秒数是 `time * 60 / bpm / 32`。 |
| `holdTime` | 长按的长度，和 `time` 同一单位。其他类型写 `0`。 |
| `positionX` | 相对这条判定线中心的横向位置。`0` 在线的中心。 |
| `speed` | 这个音符自己的速度倍率。 |
| `floorPosition` | 这个音符在线上的路程读数，和速度事件积分出来的位置对应。 |

噪域的时间已经是秒。把噪域对准某个音符时，先把那个音符的 `time` 乘 `60 / bpm / 32`，再把得到的秒写进噪域。不要把秒再乘一次。

## 2. 画面大小

下文的像素一律按 **1920×1080** 算。宽 1920，高 1080。宽高比是 `1920 / 1080 = 16 / 9`。

谱面百分比的原点在画面左下角：

- `x = 0` 是左边缘，`x = 1` 是右边缘。
- `y = 0` 是下边缘，`y = 1` 是上边缘。
- `(0.5, 0.5)` 是画面正中，也就是像素 `(960, 540)`，这里的 540 是从下边缘往上数。

换成像素：

```text
像素x        = 百分比x × 1920
从下往上的像素y = 百分比y × 1080
从上往下的像素y = (1 - 百分比y) × 1080
```

一块矩形：

```text
像素宽 = |右上x - 左下x| × 1920
像素高 = |右上y - 左下y| × 1080
中心像素x = (左下x + 右上x) / 2 × 1920
中心从下往上的像素y = (左下y + 右上y) / 2 × 1080
```

在 1920×1080 上，1 像素对应的世界长度横竖相同，都是 `1/108`。整屏高是 10 个世界单位，整屏宽是 `10 × 16 / 9 = 160/9`，大约 17.778 个世界单位。所以：

```text
世界x = (百分比x - 0.5) × 10 × (1920 / 1080)
世界y = (百分比y - 0.5) × 10
像素距离 = 世界距离 × 108
```

缩放再乘到宽高上。`scale.x = 2` 时，像素宽变成原来的 2 倍。旋转之后，外接框会变，矩形自己的宽高数字仍按未旋转时的百分比差再乘缩放。

## 3. blockAreaList 的结构

`blockAreaList` 是数组。每一项是一块矩形噪域。

```json
{
  "bottomLeftPercentage": { "x": 0.25, "y": 0.30 },
  "topRightPercentage": { "x": 0.75, "y": 0.50 },
  "appearTime": 8.0,
  "enableTime": 12.0,
  "disableTime": 14.0,
  "disappearTime": 15.0,
  "isSubtract": false,
  "color": "#FF0000",
  "moveEvents": [],
  "scaleEvents": [],
  "rotateEvents": []
}
```

### 3.1 区域自身的字段

| 字段 | 类型 | 缺省 | 有效情况 | 作用 |
| --- | --- | --- | --- | --- |
| `bottomLeftPercentage` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 矩形的一个角 |
| `topRightPercentage` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 矩形的对角 |
| `appearTime` | 秒 | `0` | 有限数 | 从这一秒开始显示 |
| `enableTime` | 秒 | `0` | 有限数 | 从这一秒开始挡住触摸，并进入完整噪域 |
| `disableTime` | 秒 | `0` | 有限数 | 到这一秒停止挡住触摸，这一秒本身不包含在内 |
| `disappearTime` | 秒 | `0` | 有限数 | 到这一秒停止显示，这一秒本身不包含在内 |
| `isSubtract` | 布尔 | `false` | `true` 或 `false` | `false` 是普通区域，`true` 是挖空 |
| `color` | 颜色 | 红 `(1, 0, 0)` | 见下方 | 噪域材质的颜色。不写时用红色 |
| `moveEvents` | 数组 | `[]` | 见移动事件 | 中心往哪个百分比点移动 |
| `scaleEvents` | 数组 | `[]` | 见缩放事件 | 宽高倍率 |
| `rotateEvents` | 数组 | `[]` | 见旋转事件 | 绕锚点转多少度 |

`color` 可以写成 `"#FF0000"`、`"#F00"`、`"rgb(255, 0, 0)"`、`[1, 0, 0]`，或 `{ "r": 1, "g": 0, "b": 0 }`。三个数里只要有一个大于 1，就按 0 到 255 读。不写、写错，或写成纯红，噪域都是现在这套红色材质。别的颜色会按这套红材质的明暗换过去。同一时刻画面上若有几种颜色，用先出现的那一种。

点的字段是 `x` 和 `y`，都是第 2 节的屏幕百分比。常用范围是 0 到 1，写出这个范围仍然是合法有限数，区域就会部分或整个跑到画面外。两个角写成同一个点时，宽高为 0，这块区域不挡触摸。两个角对调，算出来的宽高相同，因为用的是差的绝对值。

按 1920×1080，上面这份矩形：

```text
像素宽 = |0.75 - 0.25| × 1920 = 960
像素高 = |0.50 - 0.30| × 1080 = 216
中心百分比 = (0.50, 0.40)
中心像素x = 960
中心从下往上 = 0.40 × 1080 = 432
中心从上往下 = 0.60 × 1080 = 648
```

时间要是有限数。读入后会收成不倒退：`enableTime` 不会早于 `appearTime`，`disableTime` 不会早于 `enableTime`，`disappearTime` 不会早于 `disableTime`。写反了不会倒放，只会把后面的时间往前抬，区间可能被挤成 0。长度为 0 的区域不会显示，也不挡触摸。

`NaN` 和无穷大会让噪域读取失败。

### 3.2 移动事件 `moveEvents`

```json
{
  "time": 12.0,
  "endPosition": { "x": 0.5, "y": 0.5 },
  "easeTypeX": 0,
  "easeTypeY": 0
}
```

| 字段 | 类型 | 缺省 | 有效情况 | 作用 |
| --- | --- | --- | --- | --- |
| `time` | 秒 | `0` | 有限数 | 这一帧的时刻 |
| `endPosition` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 矩形中心要去的屏幕百分比位置 |
| `endPosition.x` | 数 | `0` | 有限数 | 目标中心的横向百分比 |
| `endPosition.y` | 数 | `0` | 有限数 | 目标中心的纵向百分比 |
| `easeTypeX` | 整数 | `0` | `0` 到 `14` | 从这一帧走到下一帧时，横轴用的缓动 |
| `easeTypeY` | 整数 | `0` | `0` 到 `14` | 纵轴用的缓动 |

`endPosition` 是中心的目的地，不是在当前位置上再加一段位移。写成矩形原来的中心，这一帧就不产生移动。写成 `(0.5, 0.5)`，中心就到画面正中，像素 `(960, 540)`（从下往上数）。

缓动写在一段的起点上。最后一帧没有下一段，它的缓动不会被用到，值会一直保持。

### 3.3 缩放事件 `scaleEvents`

```json
{
  "time": 12.0,
  "scale": { "x": 1.0, "y": 1.0 },
  "anchor": { "x": 0.5, "y": 0.5 },
  "easeTypeX": 0,
  "easeTypeY": 0
}
```

| 字段 | 类型 | 缺省 | 有效情况 | 作用 |
| --- | --- | --- | --- | --- |
| `time` | 秒 | `0` | 有限数 | 这一帧的时刻 |
| `scale` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 宽和高的倍率 |
| `scale.x` | 数 | `0` | 有限数 | 乘在像素宽上 |
| `scale.y` | 数 | `0` | 有限数 | 乘在像素高上 |
| `anchor` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 缩放时钉在屏幕上的那一点 |
| `anchor.x` | 数 | `0` | 有限数 | 锚点横向百分比 |
| `anchor.y` | 数 | `0` | 有限数 | 锚点纵向百分比 |
| `easeTypeX` | 整数 | `0` | `0` 到 `14` | 横轴缓动，写在这段起点 |
| `easeTypeY` | 整数 | `0` | `0` 到 `14` | 纵轴缓动 |

`scale` 为 `1` 是原始大小，`2` 是该方向两倍，`0` 是该方向没有厚度。判定用的宽高取绝对值，所以负数不会得到负的像素宽高。

空数组表示倍率一直是 1。注意缺省的单个 `scale` 是 `(0, 0)`，那是「这一帧写成 0」。不要把「不写缩放数组」和「写了一帧 scale 为 0」当成一回事。

像素：

```text
像素宽 = |右上x - 左下x| × 1920 × |scale.x|
像素高 = |右上y - 左下y| × 1080 × |scale.y|
```

锚点用屏幕百分比。锚点在矩形中心，矩形原地放大。锚点在某个角上，矩形从那个角往外长。

### 3.4 旋转事件 `rotateEvents`

```json
{
  "time": 12.0,
  "rotation": 0,
  "anchor": { "x": 0.5, "y": 0.4 },
  "easeType": 0
}
```

| 字段 | 类型 | 缺省 | 有效情况 | 作用 |
| --- | --- | --- | --- | --- |
| `time` | 秒 | `0` | 有限数 | 这一帧的时刻 |
| `rotation` | 度 | `0` | 有限数 | 这一帧的角度。正角度在 y 向上的坐标里是逆时针 |
| `anchor` | 点 | `(0, 0)` | `x`、`y` 为有限数 | 旋转绕着的屏幕百分比点 |
| `anchor.x` | 数 | `0` | 有限数 | 锚点横向百分比 |
| `anchor.y` | 数 | `0` | 有限数 | 锚点纵向百分比 |
| `easeType` | 整数 | `0` | `0` 到 `14` | 从这一帧转到下一帧的缓动 |

空数组表示角度一直是 0。锚点在中心，矩形自旋。锚点在别的地方，整块矩形绕那一点转。

### 3.5 一段示例

```json
"blockAreaList": [
  {
    "bottomLeftPercentage": { "x": 0.25, "y": 0.30 },
    "topRightPercentage": { "x": 0.75, "y": 0.50 },
    "appearTime": 8.0,
    "enableTime": 12.0,
    "disableTime": 14.0,
    "disappearTime": 15.0,
    "isSubtract": false,
    "scaleEvents": [
      {
        "time": 8.0,
        "scale": { "x": 0.0, "y": 0.0 },
        "anchor": { "x": 0.5, "y": 0.4 },
        "easeTypeX": 0,
        "easeTypeY": 0
      },
      {
        "time": 12.0,
        "scale": { "x": 1.0, "y": 1.0 },
        "anchor": { "x": 0.5, "y": 0.4 },
        "easeTypeX": 0,
        "easeTypeY": 0
      }
    ],
    "rotateEvents": [
      {
        "time": 12.0,
        "rotation": 0,
        "anchor": { "x": 0.5, "y": 0.4 },
        "easeType": 0
      },
      {
        "time": 12.0,
        "rotation": 75,
        "anchor": { "x": 0.5, "y": 0.4 },
        "easeType": 0
      }
    ],
    "moveEvents": [
      {
        "time": 12.0,
        "endPosition": { "x": 0.5, "y": 0.4 },
        "easeTypeX": 0,
        "easeTypeY": 0
      },
      {
        "time": 14.0,
        "endPosition": { "x": 0.5, "y": 0.5 },
        "easeTypeX": 0,
        "easeTypeY": 0
      }
    ]
  }
]
```

这块区域在 1920×1080 上的原始矩形是 960×216 像素，中心在 `(960, 432)`（y 从下往上）。

- 8 秒出现，12 秒开始挡，14 秒停止挡，15 秒消失。8 到 11.5 秒是暗色预告，11.5 到 12 秒是提示，12 到 14 秒是完整噪域。
- 缩放第一帧是 0，所以 12 秒之前宽高都是 0，不挡触摸。8 到 12 秒匀速张到 1 倍，12 秒时才是 960×216。
- 两个旋转帧都写在 12 秒，后面那帧是 75 度。长度是 0，结果立刻是 75 度，12 秒之前也已经是 75 度。锚点 `(0.5, 0.4)` 就是矩形中心，像素 `(960, 432)`。
- 移动第一帧的目的地就是原始中心，所以 12 秒之前中心不跑。12 到 14 秒匀速移到 `(0.5, 0.5)`，也就是像素 `(960, 540)`。14 秒之后停在那里，直到 15 秒消失。

顺序是先用缩放得到 960×216，再绕中心转到 75 度，最后把中心从 y=432 送到 y=540。

## 4. blockArea 的特性

这些是读字段表时容易漏掉的行为。

1. 四段时间读入后会被收成不倒退。写反不会倒放，后面的时间会被抬到前面的时间上。
2. 结束时刻不包含在内。`disableTime` 那一秒已经不挡，`disappearTime` 那一秒已经不显示。
3. 提示阶段是固定的 `enableTime - 0.5` 秒，谱面里没有字段能改这 0.5 秒。`appearTime` 若晚于这个时刻，提示会被裁短。
4. 暗色预告从 `appearTime` 起用 0.5 秒淡入。`disableTime` 之后没有淡出，画面保持到 `disappearTime`。
5. 一组动画只要有第一帧，播放时间还没到，也先采用第一帧。不想提前生效，就把第一帧写成原始状态，用第二帧写变化。
6. 同一组里按 `time` 排序。`time` 相同的帧保持 JSON 里的先后。长度为 0 的一段会立刻走到后一帧，所以同一秒上想看见的值要写在后面。
7. 三组动画的叠加顺序固定：先缩放，再旋转，最后移动。
8. 缩放数组为空时倍率是 1。第一帧写成 0 时，到下一帧之前该方向没有厚度，不挡触摸。
9. 某一侧的像素尺寸小到可以当成 0 时，整块区域都不参与挡住判定。
10. 缓动编号写在一段的起点上。最后一帧的缓动没有下一段可用。
11. 进度按 0.01 的台阶计算，再在相邻台阶之间补一下。很短的一段不会比这个台阶更细。具体函数在第 5 节。
12. 普通区域每一侧缩进 0.3 个世界单位。在 1080 高的画面上，`0.3 × 108 = 32.4` 像素。区域太小时，缩进不超过该方向半条边的 25%。落在这圈边缘上的触摸不算被挡住。
13. 挖空是翻转「在不在里面」，不是「这块永远不挡」。单独一块挖空仍然挡住内部。两块挖空重叠会互相抵消。普通区域中间叠一块挖空，才是开洞。
14. 手指一旦被挡住，就一直保持到松手。滑出区域、时间离开 enable 区间、区域缩走，都不会中途恢复。
15. 同时按下的手指都会参加判定。跟着手指的光晕最多同时出现 10 个，第 11 根仍然可以挡判定。

## 5. 缓动列表

编号只允许 `0` 到 `14`。进度 `t` 先限制在 0 到 1。实际用的是 `ease`，它把 `easeRaw` 按 0.01 取样再补上零头。

| 编号 | 名称 | `easeRaw` |
| --- | --- | --- |
| 0 | `Linear` | `t`。缺省就是这个 |
| 1 | `EaseInSine` | `1 - cos(t * π / 2)` |
| 2 | `EaseOutSine` | `sin(t * π / 2)` |
| 3 | `EaseInOutSine` | `(1 - cos(π * t)) / 2` |
| 4 | `EaseInQuad` | `t²` |
| 5 | `EaseOutQuad` | `1 - (1 - t)²` |
| 6 | `EaseInOutQuad` | `t < 0.5 ? 2t² : 1 - (-2t + 2)² / 2` |
| 7 | `EaseInCubic` | `t³` |
| 8 | `EaseOutCubic` | `1 - (1 - t)³` |
| 9 | `EaseInOutCubic` | `t < 0.5 ? 4t³ : 1 - (-2t + 2)³ / 2` |
| 10 | `EaseInQuart` | `t⁴` |
| 11 | `EaseOutQuart` | `1 - (1 - t)⁴` |
| 12 | `EaseInOutQuart` | `t < 0.5 ? 8t⁴ : 1 - (-2t + 2)⁴ / 2` |
| 13 | `ConstantZero` | 永远是 `0`。整段停在上一帧，到下一帧的时刻再跳过去 |
| 14 | `ConstantOne` | 永远是 `1`。整段一开始就是下一帧的值 |

```javascript
const Ease = {
  Linear: 0,
  EaseInSine: 1,
  EaseOutSine: 2,
  EaseInOutSine: 3,
  EaseInQuad: 4,
  EaseOutQuad: 5,
  EaseInOutQuad: 6,
  EaseInCubic: 7,
  EaseOutCubic: 8,
  EaseInOutCubic: 9,
  EaseInQuart: 10,
  EaseOutQuart: 11,
  EaseInOutQuart: 12,
  ConstantZero: 13,
  ConstantOne: 14,
};

function easeRaw(type, t) {
  t = Math.min(1, Math.max(0, t));
  const PI = Math.PI;
  switch (type | 0) {
    case Ease.EaseInSine: return 1 - Math.cos(t * PI / 2);
    case Ease.EaseOutSine: return Math.sin(t * PI / 2);
    case Ease.EaseInOutSine: return (1 - Math.cos(PI * t)) / 2;
    case Ease.EaseInQuad: return t * t;
    case Ease.EaseOutQuad: return 1 - (1 - t) ** 2;
    case Ease.EaseInOutQuad: return t < 0.5 ? 2 * t * t : 1 - ((-2 * t + 2) ** 2) / 2;
    case Ease.EaseInCubic: return t ** 3;
    case Ease.EaseOutCubic: return 1 - (1 - t) ** 3;
    case Ease.EaseInOutCubic: return t < 0.5 ? 4 * t ** 3 : 1 - ((-2 * t + 2) ** 3) / 2;
    case Ease.EaseInQuart: return t ** 4;
    case Ease.EaseOutQuart: return 1 - (1 - t) ** 4;
    case Ease.EaseInOutQuart: return t < 0.5 ? 8 * t ** 4 : 1 - ((-2 * t + 2) ** 4) / 2;
    case Ease.ConstantZero: return 0;
    case Ease.ConstantOne: return 1;
    case Ease.Linear:
    default: return t;
  }
}

// 谱面实际使用的缓动：先按 0.01 取样，再补上零头。
function ease(type, t) {
  const p = Math.min(1, Math.max(0, t)) * 100;
  const i = Math.floor(p);
  const a = easeRaw(type, i / 100);
  const b = easeRaw(type, Math.min(100, i + 1) / 100);
  return a + (b - a) * (p - i);
}

// 一段事件：now 在 startTime 和 endTime 之间，从 startValue 走到 endValue。
function segment(now, startTime, endTime, startValue, endValue, easeType) {
  if (endTime <= startTime) return endValue;
  const progress = Math.min(1, Math.max(0, (now - startTime) / (endTime - startTime)));
  if (now >= endTime) return endValue;
  return startValue + (endValue - startValue) * ease(easeType, progress);
}
```

用第 3.5 节的移动做一次数值检查。12 秒到 14 秒，中心 y 从 0.4 走到 0.5，缓动是 0。13 秒正好走完一半：

```javascript
segment(13, 12, 14, 0.4, 0.5, Ease.Linear); // 0.45
```

0.45 的像素高度是 `0.45 × 1080 = 486`，从下往上数。横轴这段没有变化，像素 x 仍是 `0.5 × 1920 = 960`。
