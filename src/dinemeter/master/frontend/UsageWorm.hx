package dinemeter.master.frontend;

import dinemeter.DataRecord;
import haxe.Serializer;
import js.Lib;
import js.DomCanvas;

import easelhx.display.Stage;
import easelhx.display.Shape;

using Lambda;
using dinemeter.DataRecord;


/**
 *  This file is part of DiNeMeterMaster.
 *
 *  DiNeMeterMaster is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU Affero General Public License as
 *  published by the Free Software Foundation, either version 3 of the
 *  License, or any later version.
 *
 *  DiNeMeterMaster is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Affero General Public License for more details.
 *
 *  You should have received a copy of the GNU Affero General Public License
 *  along with DiNeMeterMaster.  If not, see <http://www.gnu.org/licenses/>.
 *
 * @author othrayte
 */

class UsageWorm {
	var canvas:DomCanvas;
	var stage:Stage;
	var bg:Shape;
	var dlLine:Shape;
	var ulLine:Shape;
	var width:Float;
	var height:Float;
	
	var dScale:Float;
	var uScale:Float;
	
	public function new(id:String) {
		canvas = cast Lib.document.getElementById(id);
		stage = new Stage(canvas);
		
		width = canvas.width;
		height = canvas.height;
		
		bg = new Shape();
		
		bg.graphics.beginStroke("#FFF")
			.drawRect(0, 0, width, height)
			.endFill();
		
		bg.graphics.beginStroke("#47A")
			.moveTo(1, 2*height/3)
			.lineTo(width-1, 2*height/3)
			.endStroke();
		
		stage.addChild(bg);	
		
		dlLine = new Shape();
		stage.addChild(dlLine);
		
		ulLine = new Shape();
		stage.addChild(ulLine);
		
		stage.tick();
	}
	
	public function display(data:DataList<DataRecord>, start:Int, now:Int , end:Int, downQuota:Int, upQuota:Int, showDL:Bool, showUL:Bool) {
		if (!showDL && !showUL) return;
		var total:DataRecord = new DataRecord();
		var res:Int = Math.round((end - start) / (width - 2));
        var vals:DataList<DataRecord> = data.refactor(start, now+res, res);
        var sorted:Array<DataRecord> = new Array();
        var totaled:Array<{down:Float, up:Float}> = new Array();
        
        for (item in vals) {
            sorted[Math.round((item.start - start) / res)] = item;
        }
        
        for (i in 0 ... sorted.length) {
            if (sorted[i] != null) {
                total.down += sorted[i].down;
                total.up += sorted[i].up;
            }
            var daysLeft:Float = (end - start - i*res) / (60 * 60 * 24);
            totaled.push({down:(downQuota-total.down)/daysLeft, up:(upQuota-total.up)/daysLeft});
        }
        
        dScale = (height / 3) / (downQuota / ((end - start) / (60 * 60 * 24)));
        uScale = (height / 3) / (upQuota / ((end - start) / (60 * 60 * 24)));
        
        dlLine.graphics.clear();
        ulLine.graphics.clear();

        if (showDL) {
            dlLine.graphics.beginStroke("red").moveTo(1, canvas.height - totaled[0].down*dScale);
            for (i in 1 ... totaled.length) {
                dlLine.graphics.lineTo(i + 1, canvas.height - totaled[i].down * dScale);
            }
            dlLine.graphics.endStroke();
        }
        if (showUL) {
            ulLine.graphics.beginStroke("orange").moveTo(1, canvas.height - totaled[0].up*uScale);
            for (i in 1 ... totaled.length) {
                ulLine.graphics.lineTo(i + 1, canvas.height - totaled[i].up * uScale);
            }
            ulLine.graphics.endStroke();
        }
        
        stage.tick();
	}
	
}