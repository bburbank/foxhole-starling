/*
Copyright (c) 2012 Josh Tynjala

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
package org.josht.starling.foxhole.controls
{
	import flash.geom.Point;

	import org.josht.starling.foxhole.controls.supportClasses.ListDataContainer;
	import org.josht.starling.foxhole.core.FoxholeControl;
	import org.josht.starling.foxhole.data.ListCollection;
	import org.josht.starling.foxhole.layout.HorizontalLayout;
	import org.josht.starling.foxhole.layout.ILayout;
	import org.josht.starling.foxhole.layout.IVirtualLayout;
	import org.josht.starling.foxhole.layout.VerticalLayout;
	import org.osflash.signals.ISignal;
	import org.osflash.signals.Signal;

	import starling.display.DisplayObject;
	import starling.events.TouchEvent;

	/**
	 * Displays a one-dimensional list of items. Supports scrolling.
	 */
	public class List extends FoxholeControl
	{
		/**
		 * @private
		 */
		private static const helperPoint:Point = new Point();
		
		/**
		 * Constructor.
		 */
		public function List()
		{
			super();
		}

		/**
		 * @private
		 * The Scroller instance.
		 */
		protected var scroller:Scroller;

		/**
		 * @private
		 * The guts of the List's functionality. Handles layout and selection.
		 */
		protected var dataContainer:ListDataContainer;
		
		/**
		 * @private
		 */
		private var _scrollToIndex:int = -1;

		/**
		 * @private
		 */
		private var _layout:ILayout;

		/**
		 * The layout algorithm used to position and, optionally, size the
		 * list's items.
		 */
		public function get layout():ILayout
		{
			return this._layout;
		}

		/**
		 * @private
		 */
		public function set layout(value:ILayout):void
		{
			if(this._layout == value)
			{
				return;
			}
			this._layout = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}

		/**
		 * @private
		 */
		protected var _horizontalScrollPosition:Number = 0;

		/**
		 * The number of pixels the list has been scrolled horizontally (on
		 * the x-axis).
		 */
		public function get horizontalScrollPosition():Number
		{
			return this._horizontalScrollPosition;
		}

		/**
		 * @private
		 */
		public function set horizontalScrollPosition(value:Number):void
		{
			if(this._horizontalScrollPosition == value)
			{
				return;
			}
			this._horizontalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this._onScroll.dispatch(this);
		}

		/**
		 * @private
		 */
		protected var _maxHorizontalScrollPosition:Number = 0;

		/**
		 * The maximum number of pixels the list may be scrolled horizontally
		 * (on the x-axis). This value is automatically calculated using the
		 * layout algorithm. The <code>horizontalScrollPosition</code> property
		 * may have a higher value than the maximum due to elastic edges.
		 * However, once the user stops interacting with the list, it will
		 * automatically animate back to the maximum (or minimum, if below 0).
		 */
		public function get maxHorizontalScrollPosition():Number
		{
			return this._maxHorizontalScrollPosition;
		}
		
		/**
		 * @private
		 */
		protected var _verticalScrollPosition:Number = 0;
		
		/**
		 * The number of pixels the list has been scrolled vertically (on
		 * the y-axis).
		 */
		public function get verticalScrollPosition():Number
		{
			return this._verticalScrollPosition;
		}
		
		/**
		 * @private
		 */
		public function set verticalScrollPosition(value:Number):void
		{
			if(this._verticalScrollPosition == value)
			{
				return;
			}
			this._verticalScrollPosition = value;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
			this._onScroll.dispatch(this);
		}
		
		/**
		 * @private
		 */
		protected var _maxVerticalScrollPosition:Number = 0;
		
		/**
		 * The maximum number of pixels the list may be scrolled vertically (on
		 * the y-axis). This value is automatically calculated based on the
		 * total combined height of the list's item renderers. The
		 * <code>verticalScrollPosition</code> property may have a higher value
		 * than the maximum due to elastic edges. However, once the user stops
		 * interacting with the list, it will automatically animate back to the
		 * maximum (or minimum, if below 0).
		 */
		public function get maxVerticalScrollPosition():Number
		{
			return this._maxVerticalScrollPosition;
		}
		
		/**
		 * @private
		 */
		protected var _dataProvider:ListCollection;
		
		/**
		 * The collection of data displayed by the list.
		 */
		public function get dataProvider():ListCollection
		{
			return this._dataProvider;
		}
		
		/**
		 * @private
		 */
		public function set dataProvider(value:ListCollection):void
		{
			if(this._dataProvider == value)
			{
				return;
			}
			if(this._dataProvider)
			{
				this._dataProvider.onReset.remove(dataProvider_onReset);
			}
			this._dataProvider = value;
			if(this._dataProvider)
			{
				this._dataProvider.onReset.add(dataProvider_onReset);
			}

			//reset the scroll position because this is a drastic change and
			//the data is probably completely different
			this.horizontalScrollPosition = 0;
			this.verticalScrollPosition = 0;

			this.invalidate(INVALIDATION_FLAG_DATA);
		}
		
		/**
		 * @private
		 */
		private var _isSelectable:Boolean = true;
		
		/**
		 * Determines if an item in the list may be selected.
		 */
		public function get isSelectable():Boolean
		{
			return this._isSelectable;
		}
		
		/**
		 * @private
		 */
		public function set isSelectable(value:Boolean):void
		{
			if(this._isSelectable == value)
			{
				return;
			}
			this._isSelectable = value;
			if(!this._isSelectable)
			{
				this.selectedIndex = -1;
			}
			this.invalidate(INVALIDATION_FLAG_SELECTED);
		}
		
		/**
		 * @private
		 */
		private var _selectedIndex:int = -1;
		
		/**
		 * The index of the currently selected item. Returns -1 if no item is
		 * selected.
		 */
		public function get selectedIndex():int
		{
			return this._selectedIndex;
		}
		
		/**
		 * @private
		 */
		public function set selectedIndex(value:int):void
		{
			if(this._selectedIndex == value)
			{
				return;
			}
			this._selectedIndex = value;
			this.invalidate(INVALIDATION_FLAG_SELECTED);
			this._onChange.dispatch(this);
		}
		
		/**
		 * The currently selected item. Returns null if no item is selected.
		 */
		public function get selectedItem():Object
		{
			if(!this._dataProvider || this._selectedIndex < 0 || this._selectedIndex >= this._dataProvider.length)
			{
				return null;
			}
			
			return this._dataProvider.getItemAt(this._selectedIndex);
		}
		
		/**
		 * @private
		 */
		public function set selectedItem(value:Object):void
		{
			this.selectedIndex = this._dataProvider.getItemIndex(value);
		}
		
		/**
		 * @private
		 */
		protected var _onChange:Signal = new Signal(List);
		
		/**
		 * Dispatched when the selected item changes.
		 */
		public function get onChange():ISignal
		{
			return this._onChange;
		}
		
		/**
		 * @private
		 */
		protected var _onScroll:Signal = new Signal(List);
		
		/**
		 * Dispatched when the list is scrolled.
		 */
		public function get onScroll():ISignal
		{
			return this._onScroll;
		}
		
		/**
		 * @private
		 */
		protected var _onItemTouch:Signal = new Signal(List, Object, int, TouchEvent);
		
		/**
		 * Dispatched when an item in the list is touched (in any touch phase).
		 */
		public function get onItemTouch():ISignal
		{
			return this._onItemTouch;
		}
		
		/**
		 * @private
		 */
		private var _scrollerProperties:Object = {};
		
		/**
		 * A set of key/value pairs to be passed down to the list's scroller
		 * instance. The scroller is a Foxhole Scroller control.
		 */
		public function get scrollerProperties():Object
		{
			return this._scrollerProperties;
		}
		
		/**
		 * @private
		 */
		public function set scrollerProperties(value:Object):void
		{
			if(this._scrollerProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = {};
			}
			this._scrollerProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _itemRendererProperties:Object = {};

		/**
		 * A set of key/value pairs to be passed down to all of the list's item
		 * renderers. These values are shared by each item renderer, so values
		 * that cannot be shared (such as display objects that need to be added
		 * to the display list) should be passed to item renderers in another
		 * way (such as with an <code>AddedWatcher</code>).
		 * 
		 * @see AddedWatcher
		 */
		public function get itemRendererProperties():Object
		{
			return this._itemRendererProperties;
		}

		/**
		 * @private
		 */
		public function set itemRendererProperties(value:Object):void
		{
			if(this._itemRendererProperties == value)
			{
				return;
			}
			if(!value)
			{
				value = {};
			}
			this._itemRendererProperties = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		private var _backgroundSkin:DisplayObject;
		
		/**
		 * A display object displayed behind the item renderers.
		 */
		public function get backgroundSkin():DisplayObject
		{
			return this._backgroundSkin;
		}
		
		/**
		 * @private
		 */
		public function set backgroundSkin(value:DisplayObject):void
		{
			if(this._backgroundSkin == value)
			{
				return;
			}
			
			if(this._backgroundSkin && this._backgroundSkin != this._backgroundDisabledSkin)
			{
				this.removeChild(this._backgroundSkin);
			}
			this._backgroundSkin = value;
			if(this._backgroundSkin && this._backgroundSkin.parent != this)
			{
				this._backgroundSkin.visible = false;
				this.addChildAt(this._backgroundSkin, 0);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _backgroundDisabledSkin:DisplayObject;
		
		/**
		 * A background to display when the list is disabled.
		 */
		public function get backgroundDisabledSkin():DisplayObject
		{
			return this._backgroundDisabledSkin;
		}
		
		/**
		 * @private
		 */
		public function set backgroundDisabledSkin(value:DisplayObject):void
		{
			if(this._backgroundDisabledSkin == value)
			{
				return;
			}
			
			if(this._backgroundDisabledSkin && this._backgroundDisabledSkin != this._backgroundSkin)
			{
				this.removeChild(this._backgroundDisabledSkin);
			}
			this._backgroundDisabledSkin = value;
			if(this._backgroundDisabledSkin && this._backgroundDisabledSkin.parent != this)
			{
				this._backgroundDisabledSkin.visible = false;
				this.addChildAt(this._backgroundDisabledSkin, 0);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _paddingTop:Number = 0;

		/**
		 * The minimum space, in pixels, between the list's top edge and the
		 * list's content.
		 */
		public function get paddingTop():Number
		{
			return this._paddingTop;
		}

		/**
		 * @private
		 */
		public function set paddingTop(value:Number):void
		{
			if(this._paddingTop == value)
			{
				return;
			}
			this._paddingTop = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _paddingRight:Number = 0;

		/**
		 * The minimum space, in pixels, between the list's right edge and the
		 * list's content.
		 */
		public function get paddingRight():Number
		{
			return this._paddingRight;
		}

		/**
		 * @private
		 */
		public function set paddingRight(value:Number):void
		{
			if(this._paddingRight == value)
			{
				return;
			}
			this._paddingRight = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _paddingBottom:Number = 0;

		/**
		 * The minimum space, in pixels, between the list's bottom edge and
		 * the list's content.
		 */
		public function get paddingBottom():Number
		{
			return this._paddingBottom;
		}

		/**
		 * @private
		 */
		public function set paddingBottom(value:Number):void
		{
			if(this._paddingBottom == value)
			{
				return;
			}
			this._paddingBottom = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}

		/**
		 * @private
		 */
		protected var _paddingLeft:Number = 0;

		/**
		 * The minimum space, in pixels, between the list's left edge and the
		 * list's content.
		 */
		public function get paddingLeft():Number
		{
			return this._paddingLeft;
		}

		/**
		 * @private
		 */
		public function set paddingLeft(value:Number):void
		{
			if(this._paddingLeft == value)
			{
				return;
			}
			this._paddingLeft = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _itemRendererType:Class = DefaultItemRenderer;
		
		/**
		 * The class used to instantiate item renderers.
		 */
		public function get itemRendererType():Class
		{
			return this._itemRendererType;
		}
		
		/**
		 * @private
		 */
		public function set itemRendererType(value:Class):void
		{
			if(this._itemRendererType == value)
			{
				return;
			}
			
			this._itemRendererType = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _itemRendererFunction:Function;
		
		/**
		 * A function called that is expected to return a new item renderer. Has
		 * a higher priority than <code>itemRendererType</code>.
		 * 
		 * @see itemRendererType
		 */
		public function get itemRendererFunction():Function
		{
			return this._itemRendererFunction;
		}
		
		/**
		 * @private
		 */
		public function set itemRendererFunction(value:Function):void
		{
			if(this._itemRendererFunction === value)
			{
				return;
			}
			
			this._itemRendererFunction = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * @private
		 */
		private var _typicalItem:Object = null;
		
		/**
		 * Used to auto-size the list. If the list's width or height is NaN, the
		 * list will try to automatically pick an ideal size. This item is
		 * used in that process to create a sample item renderer.
		 */
		public function get typicalItem():Object
		{
			return this._typicalItem;
		}
		
		/**
		 * @private
		 */
		public function set typicalItem(value:Object):void
		{
			if(this._typicalItem == value)
			{
				return;
			}
			this._typicalItem = value;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a single property on the list's scroller instance. The
		 * scroller is a Foxhole Scroller control.
		 */
		public function setScrollerProperty(propertyName:String, propertyValue:Object):void
		{
			this._scrollerProperties[propertyName] = propertyValue;
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Sets a property value for all of the list's item renderers. This
		 * property will be shared by all item renderers, so skins and similar
		 * objects that can only be used in one place should be initialized in
		 * a different way.
		 */
		public function setItemRendererProperty(propertyName:String, propertyValue:Object):void
		{
			this._itemRendererProperties[propertyName] = propertyValue;
			if(this.dataContainer)
			{
				this.dataContainer.setItemRendererProperty(propertyName, propertyValue);
			}
			this.invalidate(INVALIDATION_FLAG_STYLES);
		}
		
		/**
		 * Scrolls the list so that the specified item is visible.
		 */
		public function scrollToDisplayIndex(index:int):void
		{
			if(this._scrollToIndex == index)
			{
				return;
			}
			this._scrollToIndex = index;
			this.invalidate(INVALIDATION_FLAG_SCROLL);
		}
		
		/**
		 * @inheritDoc
		 */
		override public function dispose():void
		{
			this._onChange.removeAll();
			this._onScroll.removeAll();
			this._onItemTouch.removeAll();
			super.dispose();
		}
		
		/**
		 * If the user is dragging the scroll, calling stopScrolling() will
		 * cause the list to ignore the drag.
		 */
		public function stopScrolling():void
		{
			if(!this.scroller)
			{
				return;
			}
			this.scroller.stopScrolling();
		}
		
		/**
		 * @private
		 */
		override protected function initialize():void
		{
			if(!this._layout)
			{
				const layout:VerticalLayout = new VerticalLayout();
				layout.useVirtualLayout = true;
				layout.paddingTop = layout.paddingRight = layout.paddingBottom =
					layout.paddingLeft = 0;
				layout.gap = 0;
				layout.horizontalAlign = VerticalLayout.HORIZONTAL_ALIGN_JUSTIFY;
				layout.verticalAlign = HorizontalLayout.VERTICAL_ALIGN_TOP;
				this._layout = layout;
			}

			if(!this.scroller)
			{
				this.scroller = new Scroller();
				this.scroller.nameList.add("foxhole-list-scroller");
				this.scroller.verticalScrollPolicy = Scroller.SCROLL_POLICY_AUTO;
				this.scroller.horizontalScrollPolicy = Scroller.SCROLL_POLICY_AUTO;
				this.scroller.onScroll.add(scroller_onScroll);
				this.addChild(this.scroller);
			}
			
			if(!this.dataContainer)
			{
				this.dataContainer = new ListDataContainer();
				this.dataContainer.owner = this;
				this.dataContainer.onChange.add(dataContainer_onChange);
				this.dataContainer.onItemTouch.add(dataContainer_onItemTouch);
				this.scroller.viewPort = this.dataContainer;
			}
		}
		
		/**
		 * @private
		 */
		override protected function draw():void
		{
			var sizeInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SIZE);
			const scrollInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_SCROLL);
			const stylesInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STYLES);
			const stateInvalid:Boolean = this.isInvalid(INVALIDATION_FLAG_STATE);
			
			if(stylesInvalid)
			{
				this.refreshScrollerStyles();
			}
			
			if(sizeInvalid || stylesInvalid || stateInvalid)
			{
				this.refreshBackgroundSkin();
			}
			
			if(!isNaN(this.explicitWidth))
			{
				this.dataContainer.visibleWidth = this.explicitWidth - this._paddingLeft - this._paddingRight;
			}
			if(!isNaN(this.explicitHeight))
			{
				this.dataContainer.visibleHeight = this.explicitHeight - this._paddingTop - this._paddingBottom;
			}
			this.dataContainer.isEnabled = this._isEnabled;
			this.dataContainer.isSelectable = this._isSelectable;
			this.dataContainer.selectedIndex = this._selectedIndex;
			this.dataContainer.dataProvider = this._dataProvider;
			this.dataContainer.itemRendererType = this._itemRendererType;
			this.dataContainer.itemRendererFunction = this._itemRendererFunction;
			this.dataContainer.itemRendererProperties = this._itemRendererProperties;
			this.dataContainer.typicalItem = this._typicalItem;
			this.dataContainer.layout = this._layout;
			this.dataContainer.horizontalScrollPosition = this._horizontalScrollPosition;
			this.dataContainer.verticalScrollPosition = this._verticalScrollPosition;
			
			this.scroller.isEnabled = this._isEnabled;
			this.scroller.x = this._paddingLeft;
			this.scroller.y = this._paddingTop;
			this.scroller.horizontalScrollPosition = this._horizontalScrollPosition;
			this.scroller.verticalScrollPosition = this._verticalScrollPosition;

			sizeInvalid = this.autoSizeIfNeeded() || sizeInvalid;

			if(sizeInvalid)
			{
				this.scroller.width = this.actualWidth - this._paddingLeft - this._paddingRight;
				this.scroller.height = this.actualHeight - this._paddingTop - this._paddingBottom;
			}

			this.scroller.validate();
			this._maxHorizontalScrollPosition = this.scroller.maxHorizontalScrollPosition;
			this._maxVerticalScrollPosition = this.scroller.maxVerticalScrollPosition;
			this._horizontalScrollPosition = this.scroller.horizontalScrollPosition;
			this._verticalScrollPosition = this.scroller.verticalScrollPosition;

			if(this._scrollToIndex >= 0)
			{
				const item:Object = this._dataProvider.getItemAt(this._scrollToIndex);
				if(item)
				{
					const renderer:DisplayObject = this.dataContainer.itemToItemRenderer(item) as DisplayObject;
					if(renderer)
					{
						helperPoint.x = this._maxHorizontalScrollPosition > 0 ? renderer.x - (this.dataContainer.visibleWidth - renderer.width) / 2 : 0;
						helperPoint.y = this._maxVerticalScrollPosition > 0 ? renderer.y - (this.dataContainer.visibleHeight - renderer.height) / 2 : 0;
					}
					else
					{
						IVirtualLayout(this._layout).getScrollPositionForItemIndexAndBounds(this._scrollToIndex, this.dataContainer.visibleWidth, this.dataContainer.visibleHeight, helperPoint);
					}
					this.horizontalScrollPosition = Math.max(0, Math.min(helperPoint.x, this._maxHorizontalScrollPosition));
					this.verticalScrollPosition = Math.max(0, Math.min(helperPoint.y, this._maxVerticalScrollPosition));
				}
				this._scrollToIndex = -1;
			}
		}

		/**
		 * @private
		 */
		protected function autoSizeIfNeeded():Boolean
		{
			const needsWidth:Boolean = isNaN(this.explicitWidth);
			const needsHeight:Boolean = isNaN(this.explicitHeight);
			if(!needsWidth && !needsHeight)
			{
				return false;
			}

			if(needsWidth)
			{
				this.scroller.width = NaN;
			}
			if(needsHeight)
			{
				this.scroller.height = NaN;
			}
			this.scroller.validate();
			var newWidth:Number = this.explicitWidth;
			var newHeight:Number = this.explicitHeight;
			if(needsWidth)
			{
				newWidth = this.scroller.width + this._paddingLeft + this._paddingRight;
			}
			if(needsHeight)
			{
				newHeight = this.scroller.height + this._paddingTop + this._paddingBottom;
			}
			this.setSizeInternal(newWidth, newHeight, false);
			return true;
		}
		
		/**
		 * @private
		 */
		protected function refreshScrollerStyles():void
		{
			for(var propertyName:String in this._scrollerProperties)
			{
				if(this.scroller.hasOwnProperty(propertyName))
				{
					var propertyValue:Object = this._scrollerProperties[propertyName];
					this.scroller[propertyName] = propertyValue;
				}
			}
		}
		
		/**
		 * @private
		 */
		protected function refreshBackgroundSkin():void
		{
			var backgroundSkin:DisplayObject = this._backgroundSkin;
			if(!this._isEnabled && this._backgroundDisabledSkin)
			{
				if(this._backgroundSkin)
				{
					this._backgroundSkin.visible = false;
				}
				backgroundSkin = this._backgroundDisabledSkin;
			}
			else if(this._backgroundDisabledSkin)
			{
				this._backgroundDisabledSkin.visible = false;
			}
			if(backgroundSkin)
			{
				backgroundSkin.visible = true;
				backgroundSkin.width = this.actualWidth;
				backgroundSkin.height = this.actualHeight;
			}
		}

		/**
		 * @private
		 */
		protected function dataProvider_onReset(collection:ListCollection):void
		{
			this.horizontalScrollPosition = 0;
			this.verticalScrollPosition = 0;
		}
		
		/**
		 * @private
		 */
		protected function scroller_onScroll(scroller:Scroller):void
		{
			this._maxHorizontalScrollPosition = this.scroller.maxHorizontalScrollPosition;
			this._maxVerticalScrollPosition = this.scroller.maxVerticalScrollPosition;
			this.horizontalScrollPosition = this.scroller.horizontalScrollPosition;
			this.verticalScrollPosition = this.scroller.verticalScrollPosition;
		}
		
		/**
		 * @private
		 */
		protected function dataContainer_onChange(dataContainer:ListDataContainer):void
		{
			this.selectedIndex = this.dataContainer.selectedIndex;
		}
		
		/**
		 * @private
		 */
		protected function dataContainer_onItemTouch(dataContainer:ListDataContainer, item:Object, index:int, event:TouchEvent):void
		{
			this._onItemTouch.dispatch(this, item, index, event);
		}
	}
}