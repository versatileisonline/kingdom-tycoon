# Sprint authoring source

`evade-sprint-r15.rbxm` is a Studio-serialized KeyframeSequence, adapted from the
Run sequence in [Evade Animations | Character Animations v1](https://create.roblox.com/store/asset/74987847468722)
by **wifonn3**. The free source model is R6 and contains no scripts. Only its Run
motion is reused; its other animations, avatar, accessories and controls are not
installed. This file is a development asset, not a Rojo mapping or runtime script.

The adaptation converts R6 joint bases into R15 body axes, distributes torso motion
between pelvis and waist, preserves the source timing, amplifies alternating torso
roll around its center by2.6, and keeps limb chains connected. Small elbow/knee
bends accommodate R15 joints. The final pose equals the first pose for a smooth
loop. Native checks measured11.69 degrees of total torso roll versus7.42 in the
previous run;25 keys,0.65 seconds, Movement priority. Existing Action-priority sword
animation overlays it and the run continues after the swipe fades.

Rebuild in Studio by inserting source model74987847468722 into ServerStorage as
`SprintAnimationCandidate_Evade`, then running the Edit-only authoring recipe in
`tools/BuildEvadeSprintAnimation.luau`. It refuses an existing output and preserves
the source. Run `tools/CheckEvadeSprintAnimation.luau` for hierarchy, loop, timing,
priority and sway assertions. SerializationService produced this binary in Studio;
the file has not been constructed or edited externally.

Published Animation **98098361982208**, revision1, belongs to experience owner
9916983918. Roblox approved the asset. SprintConfig uses this permanent ID;
temporary preview hashes are never runtime IDs. Upload used the official Open
Cloud Assets API after the creator approved the authoring directory. No API key
or imported third-party script is installed.

Native fresh-Play checks loaded the published0.65s loop at full Movement weight,
with the existing sword swipe at full Action weight. Jump and release yielded
to existing locomotion; exhaustion stopped the clip and restored WalkSpeed16.
The new clip replaces only sprint motion; controls and stamina are unchanged.
