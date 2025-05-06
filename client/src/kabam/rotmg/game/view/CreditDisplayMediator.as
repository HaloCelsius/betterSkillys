package kabam.rotmg.game.view
{
import com.company.assembleegameclient.ui.tooltip.HoverTooltipDelegate;

import kabam.rotmg.dialogs.control.OpenDialogSignal;

import robotlegs.bender.bundles.mvcs.Mediator;
import kabam.rotmg.core.model.PlayerModel;
import kabam.rotmg.core.signals.ShowTooltipSignal;
import kabam.rotmg.core.signals.HideTooltipsSignal;
import com.company.assembleegameclient.ui.tooltip.TextToolTip;
import com.company.assembleegameclient.map.Map;
import flash.events.MouseEvent;

public class CreditDisplayMediator extends Mediator
{

   [Inject]
   public var view:CreditDisplay;
   [Inject]
   public var model:PlayerModel;
   [Inject]
   public var showTooltipSignal:ShowTooltipSignal;
   [Inject]
   public var hideTooltipSignal:HideTooltipsSignal;
   [Inject]
   protected var openDialog:OpenDialogSignal;


   override public function initialize():void
   {
      this.model.creditsChanged.add(this.onCreditsChanged);
      this.model.fameChanged.add(this.onFameChanged);
   }

   override public function destroy():void
   {
      this.model.creditsChanged.remove(this.onCreditsChanged);
      this.model.fameChanged.remove(this.onFameChanged);
   }

   private function onCreditsChanged(_arg_1:int):void
   {
      this.view.draw(_arg_1, this.model.getFame());
   }

   private function onFameChanged(_arg_1:int):void
   {
      this.view.draw(this.model.getCredits(), _arg_1);
   }


}
}//package kabam.rotmg.game.view

