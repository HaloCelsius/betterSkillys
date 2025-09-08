package kabam.rotmg.ui.view
{
import com.company.assembleegameclient.objects.Player;
import com.company.assembleegameclient.ui.ExperienceBoostTimerPopup;
import com.company.assembleegameclient.ui.StatusBar;

import flash.display.Sprite;
import flash.events.MouseEvent;
import flash.events.Event;

public class StatMetersView extends Sprite
{
    private static const TOTAL_ALLOCATED_HEIGHT:int = 65;
    private static const BAR_WIDTH:int = 176;
    private static const VERTICAL_GAP:int = 4;
    private static const RESTORATION_VERTICAL_GAP:int = 0;
    private static const RESTORATION_FIXED_HEIGHT:int = 5;

    private var expBar_:StatusBar;
    private var fameBar_:StatusBar;
    private var hpBar_:StatusBar;
    private var mpBar_:StatusBar;

    private var activeBars:Vector.<StatusBar>;
    private var areTempXpListenersAdded:Boolean = false;
    private var curXPBoost:int = -1;
    private var expTimer:ExperienceBoostTimerPopup;

    public function StatMetersView()
    {
        super();
        this.activeBars = new Vector.<StatusBar>();

        this.expBar_ = new StatusBar(176,16,5931045,5526612,"Lvl X");
        this.fameBar_ = new StatusBar(176,16,14835456,5526612,"Fame");
        this.hpBar_ = new StatusBar(176,16,14693428,5526612,"HP");
        this.mpBar_ = new StatusBar(176,16,6325472,5526612,"MP");
        this.hpBar_.y = 24;
        this.mpBar_.y = 48;
        this.expBar_.visible = true;
        this.fameBar_.visible = false;
        addChild(this.expBar_);
        addChild(this.fameBar_);
        addChild(this.hpBar_);
        addChild(this.mpBar_);

        hideAllDynamicBars();
    }

   public function update(player:Player) : void
   {
       this.activeBars.length = 0;
      var lvlText:String = "Lvl " + player.level_;
      if(lvlText != this.expBar_.labelText_.text)
      {
         this.expBar_.labelText_.text = lvlText;
         this.expBar_.labelText_.updateMetrics();
      }
      if(player.level_ != 20)
      {
          this.activeBars.push(expBar_);

         if(!this.expBar_.visible)
         {
            this.expBar_.visible = true;
            this.fameBar_.visible = false;
         }
         //this.expBar_.draw(player.exp_,player.nextLevelExp_,0);
      }
      else
      {
          this.activeBars.push(fameBar_);

         if(!this.fameBar_.visible)
         {
            this.fameBar_.visible = true;
            this.expBar_.visible = false;
         }
         //this.fameBar_.draw(player.currFame_,player.nextClassQuestFame_,0);
      }
      //this.hpBar_.draw(player.hp_,player.maxHP_,player.maxHPBoost_,player.maxHPMax_);
      //this.mpBar_.draw(player.mp_,player.maxMP_,player.maxMPBoost_,player.maxMPMax_);

       // For dynamic bars we can just add hp, however conditions that hide and show them can be added here:

       this.activeBars.push(mpBar_);
       this.activeBars.push(hpBar_);

       var numActiveBars:int = this.activeBars.length;

       if (numActiveBars == 0) {
           hideAllDynamicBars();
           return;
       }

       var heightAvailableForBars:Number = TOTAL_ALLOCATED_HEIGHT;
       var totalGapSpace:Number = 0;

       for (var i:int = 0; i < numActiveBars; i++) {
           var bar:StatusBar = this.activeBars[i]; var gapBeforeThisBar:int = VERTICAL_GAP;
           if (i == 0) {
               gapBeforeThisBar = 0;
           }
           totalGapSpace += gapBeforeThisBar;
       }

       heightAvailableForBars -= totalGapSpace;
       var calculatedResizableHeight:Number = (numActiveBars > 0 && heightAvailableForBars > 0) ? (heightAvailableForBars / numActiveBars) : 0;

       var baseIntHeight:int = Math.max(1, Math.floor(calculatedResizableHeight));
       var remainingPixels:int = 0;
       if (numActiveBars > 0 && heightAvailableForBars > 0) {
           remainingPixels = Math.floor(heightAvailableForBars) - (baseIntHeight * numActiveBars);
       }

       var currentY:Number = 0;
       hideAllDynamicBars();

       for (i = 0; i < numActiveBars; i++) {
           bar = this.activeBars[i];
           var targetBarHeight:Number = 0;
           var gap:int = VERTICAL_GAP;
           if (i == 0) {
               gap = 0;
           }

           currentY += gap;
           targetBarHeight = baseIntHeight;
           if (remainingPixels > 0) {
               targetBarHeight++; remainingPixels--;
           }

           if (targetBarHeight < 1) targetBarHeight = 1;
           bar.y = currentY;
           bar.visible = true;
           drawBarContent(bar, player);
           bar.setSize(BAR_WIDTH, targetBarHeight);
           currentY += targetBarHeight;
       }
   }

    private function hideAllDynamicBars():void {
        if (expBar_) expBar_.visible = false; if (fameBar_) fameBar_.visible = false; if (hpBar_) hpBar_.visible = false;
    }

    private function drawBarContent(bar:StatusBar, player:Player):void {
        if (bar == expBar_) { bar.draw(player.exp_, player.nextLevelExp_, 0); }
        else if (bar == fameBar_) { bar.draw(player.currFame_, player.nextClassQuestFame_, 0); }
        else if (bar == hpBar_) { bar.draw(player.hp_, player.maxHP_, player.maxHPBoost_, player.maxHPMax_, player.level_); }
        else if (bar == mpBar_) { bar.draw(player.mp_, player.maxMP_, player.maxMPBoost_, player.maxMPMax_, player.level_); }
    }

    private function onExpBarOver(event:MouseEvent):void {
        if (!expBar_ || !expBar_.visible) return;
        if (!this.expTimer) { this.expTimer = new ExperienceBoostTimerPopup(); }
        if (!this.expTimer.parent) {
            addChild(this.expTimer);
            this.expTimer.x = expBar_.x;
            this.expTimer.y = expBar_.y + expBar_.height + 2;
        }
    }

    private function onExpBarOut(event:MouseEvent):void {
        if (this.expTimer && this.expTimer.parent) {
            removeChild(this.expTimer);
            this.expTimer = null;
        }
    }
}
}
