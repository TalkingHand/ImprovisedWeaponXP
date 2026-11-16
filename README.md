# Improvised Weapon XP

Project Zomboid **Build 42** mod. Melee weapons that give no weapon skill XP in vanilla now train a weapon skill.

In vanilla B42, a melee hit gives weapon skill XP only when the weapon has one of six skill categories (Axe, Long Blunt, Spear, Long Blade, Short Blade, Short Blunt). Weapons with only the **Improvised** category give Strength and Fitness, but no weapon skill at all.

[한국어](#한국어)

## What changes

| Weapons (42.22.2) | Attack | Skill trained |
|---|---|---|
| Pen, Blue/Green/Red Pen, Fancy Pen, Multicolor Pen, Spiffo Pen, Pencil, Spiffo Pencil, Compass | Stab | Short Blade |
| Stone, Flint Nodule | Swing | Short Blunt |

- Same amount as vanilla gives a normal weapon: damage × 0.9 per hit, at most 3 (before XP multipliers).
- Weapons that already train a skill are not touched, so XP is never doubled.
- The rule goes by category, not by item name: modded weapons with no skill category follow it too (stab → Short Blade, spear → Spear, swing → Short Blunt).
- Only XP changes. Damage, crits and hit chance stay as in vanilla.
- Bare hands stay as they are (B42 has no unarmed skill). Thrown bombs, traps and firecrackers are not melee and are left alone.

## Install

- Steam Workshop: (link after upload)
- Manual: copy `Contents/mods/ImprovisedWeaponXP` to `%USERPROFILE%\Zomboid\mods\`.
- Multiplayer: add the mod to the server (XP is granted where vanilla grants it). Multiplayer is not tested.
- Safe to add to or remove from an existing save.

## License

All rights reserved. No license is granted for redistribution or modified versions.

---

## 한국어

바닐라 B42에서는 무기에 도끼·장둔기·창·장검·단검·단둔기 카테고리가 있어야 무기 숙련도가 오릅니다. **즉석 무기** 카테고리만 있는 무기는 근력·체력만 오르고 무기 숙련도는 오르지 않습니다. 이 모드는 그 잠금을 풉니다.

- 펜·연필·컴퍼스(찌르기) → 단검
- 돌멩이·부싯돌(휘두르기) → 단둔기
- 양은 바닐라 무기와 같습니다(데미지 × 0.9, 최대 3).
- 원래 숙련도가 오르는 무기는 건드리지 않아서 두 번 오르는 일은 없습니다.
- 경험치만 바뀌고 데미지·치명타·명중은 바닐라 그대로입니다.
- 기존 세이브에 넣고 빼도 됩니다. 멀티는 미검증입니다.

## Support

If this mod helps you, you can support it via [Ko-fi](https://ko-fi.com/talkinghands2285) or [PayPal](https://www.paypal.com/paypalme/TalkingHands619/3). It's optional; every feature stays free.

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/talkinghands2285)
