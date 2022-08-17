﻿using common.resources;
using System;

namespace wServer.core.objects
{
    public partial class Player
    {
        private int _canTpCooldownTime;
        private int _newbieTime;

        public bool IsVisibleToEnemy()
        {
            if (_newbieTime > 0)
                return false;

            if (HasConditionEffect(ConditionEffects.Paused))
                return false;

            if (HasConditionEffect(ConditionEffects.Invisible))
                return false;

            if (HasConditionEffect(ConditionEffects.Hidden))
                return false;

            return true;
        }

        public bool TPCooledDown() => !(_canTpCooldownTime > 0);

        internal void RestartTPPeriod() => _canTpCooldownTime = 0;

        internal void SetNewbiePeriod() => _newbieTime = 3000;

        internal void SetTPDisabledPeriod() => _canTpCooldownTime = 10000;

        private bool CanHpRegen() => !(HasConditionEffect(ConditionEffects.Bleeding) || HasConditionEffect(ConditionEffects.Sick));

        private bool CanMpRegen() => !(HasConditionEffect(ConditionEffects.Quiet) || HasConditionEffect(ConditionEffects.NinjaSpeedy));

        private void HandleEffects(ref TickTime time)
        {
            if (Client == null || Client.Account == null) return;

            if (Client.Account.Hidden && !HasConditionEffect(ConditionEffects.Hidden))
            {
                ApplyConditionEffect(ConditionEffectIndex.Hidden);
                ApplyConditionEffect(ConditionEffectIndex.Invincible);
                GameServer.ConnectionManager.Clients[Client].Hidden = true;
            }

            if (HasConditionEffect(ConditionEffects.Quiet) && MP > 0)
                MP = 0;

            if (HasConditionEffect(ConditionEffects.Bleeding) && HP > 1)
            {
                HP -= (int)(20 * time.DeltaTime); // 20 per second
                if (HP < 1)
                    HP = 1;
            }

            if (HasConditionEffect(ConditionEffects.NinjaSpeedy))
            {
                MP = Math.Max(0, (int)(MP - 10 * time.DeltaTime));

                if (MP == 0)
                    ApplyConditionEffect(ConditionEffectIndex.NinjaSpeedy, 0);
            }

            if (HasConditionEffect(ConditionEffects.NinjaBerserk))
            {
                MP = Math.Max(0, (int)(MP - 10 * time.DeltaTime));

                if (MP == 0)
                    ApplyConditionEffect(ConditionEffectIndex.NinjaBerserk, 0);
            }

            if (_newbieTime > 0)
            {
                _newbieTime -= time.ElaspedMsDelta;
                if (_newbieTime < 0)
                    _newbieTime = 0;
            }

            if (_canTpCooldownTime > 0)
            {
                _canTpCooldownTime -= time.ElaspedMsDelta;
                if (_canTpCooldownTime <= 0)
                    _canTpCooldownTime = 0;
            }
        }
    }
}
