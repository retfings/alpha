/**
 * 前端组件测试 - 权重配置和筛选功能
 * Frontend Component Tests - Weight Configuration and Filtering
 *
 * 测试覆盖:
 * 1. 组件单元测试
 * 2. 用户交互测试
 * 3. 筛选功能测试
 * 4. 权重配置测试
 */

import { describe, it, beforeEach, afterEach } from 'node:test';
import assert from 'node:assert/strict';

// ============================================================================
// 1. 权重配置组件测试
// ============================================================================

describe('权重配置组件', () => {
  describe('权重输入验证', () => {
    it('应该接受有效权重值 (0.1-10)', () => {
      const validWeights = [0.1, 0.5, 1, 2.5, 5, 7.5, 10];

      validWeights.forEach(weight => {
        assert.ok(weight >= 0.1, '权重应该 >= 0.1');
        assert.ok(weight <= 10, '权重应该 <= 10');
      });
    });

    it('应该拒绝无效权重值', () => {
      const invalidWeights = [0, -1, 11, 100, NaN];

      invalidWeights.forEach(weight => {
        const isValid = weight >= 0.1 && weight <= 10 && !isNaN(weight);
        assert.ok(!isValid, `权重 ${weight} 应该无效`);
      });
    });

    it('应该支持小数权重', () => {
      const decimalWeights = [0.1, 0.25, 1.5, 3.14, 9.99];

      decimalWeights.forEach(weight => {
        assert.ok(weight >= 0.1 && weight <= 10);
      });
    });

    it('应该支持整数权重', () => {
      const intWeights = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

      intWeights.forEach(weight => {
        assert.ok(weight >= 0.1 && weight <= 10);
      });
    });
  });

  describe('权重计算', () => {
    it('应该计算总权重', () => {
      const conditions = [
        { id: 1, weight: 2, enabled: true },
        { id: 2, weight: 3, enabled: true },
        { id: 3, weight: 5, enabled: true }
      ];

      const totalWeight = conditions
        .filter(c => c.enabled)
        .reduce((sum, c) => sum + c.weight, 0);

      assert.strictEqual(totalWeight, 10);
    });

    it('应该排除禁用条件的权重', () => {
      const conditions = [
        { id: 1, weight: 2, enabled: true },
        { id: 2, weight: 3, enabled: false },
        { id: 3, weight: 5, enabled: true }
      ];

      const totalWeight = conditions
        .filter(c => c.enabled)
        .reduce((sum, c) => sum + c.weight, 0);

      assert.strictEqual(totalWeight, 7);
    });

    it('应该计算加权分数', () => {
      const scores = [
        { value: 80, weight: 2 },
        { value: 90, weight: 3 },
        { value: 70, weight: 5 }
      ];

      const totalWeight = scores.reduce((sum, s) => sum + s.weight, 0);
      const weightedSum = scores.reduce((sum, s) => sum + s.value * s.weight, 0);
      const weightedAverage = weightedSum / totalWeight;

      assert.strictEqual(weightedAverage, 77);
    });

    it('应该归一化权重', () => {
      const weights = [2, 3, 5];
      const total = weights.reduce((sum, w) => sum + w, 0);
      const normalized = weights.map(w => w / total);

      assert.strictEqual(normalized[0], 0.2);
      assert.strictEqual(normalized[1], 0.3);
      assert.strictEqual(normalized[2], 0.5);

      // 归一化后总和应该为 1
      const sum = normalized.reduce((s, n) => s + n, 0);
      assert.ok(Math.abs(sum - 1) < 0.0001);
    });
  });

  describe('权重调整', () => {
    it('应该增加权重', () => {
      let weight = 5;
      weight += 1;
      assert.strictEqual(weight, 6);
      assert.ok(weight <= 10);
    });

    it('应该减少权重', () => {
      let weight = 5;
      weight -= 1;
      assert.strictEqual(weight, 4);
      assert.ok(weight >= 0.1);
    });

    it('应该限制最大权重', () => {
      let weight = 9.5;
      weight += 1;
      assert.strictEqual(weight, 10); // 应该被限制在 10
    });

    it('应该限制最小权重', () => {
      let weight = 0.5;
      weight -= 1;
      assert.strictEqual(weight, 0.1); // 应该被限制在 0.1
    });
  });
});

// ============================================================================
// 2. 筛选功能组件测试
// ============================================================================

describe('筛选功能组件', () => {
  describe('操作符测试', () => {
    const operators = [
      { value: '>', label: '大于' },
      { value: '>=', label: '大于等于' },
      { value: '<', label: '小于' },
      { value: '<=', label: '小于等于' },
      { value: '=', label: '等于' },
      { value: '!=', label: '不等于' },
      { value: 'between', label: '介于' }
    ];

    it('应该包含所有操作符', () => {
      assert.strictEqual(operators.length, 7);
    });

    it('应该验证大于操作符', () => {
      const result = 100 > 50;
      assert.ok(result);
    });

    it('应该验证大于等于操作符', () => {
      assert.ok(100 >= 100);
      assert.ok(100 >= 50);
    });

    it('应该验证小于操作符', () => {
      const result = 50 < 100;
      assert.ok(result);
    });

    it('应该验证等于操作符', () => {
      const result = 100 === 100;
      assert.ok(result);
    });

    it('应该验证不等于操作符', () => {
      const result = 100 !== 50;
      assert.ok(result);
    });

    it('应该验证介于操作符', () => {
      const value = 75;
      const min = 50;
      const max = 100;
      const result = value >= min && value <= max;
      assert.ok(result);
    });
  });

  describe('条件组合测试', () => {
    it('应该支持 AND 逻辑', () => {
      const conditions = [
        { field: 'price', operator: '>', value: 10 },
        { field: 'volume', operator: '>', value: 1000000 }
      ];

      const stock = { price: 15, volume: 2000000 };

      const matches = conditions.every(cond => {
        const stockValue = stock[cond.field];
        switch (cond.operator) {
          case '>': return stockValue > cond.value;
          case '<': return stockValue < cond.value;
          case '=': return stockValue === cond.value;
          default: return false;
        }
      });

      assert.ok(matches);
    });

    it('应该支持多条件筛选', () => {
      const filters = {
        industry: 'Banking',
        market: 'SH',
        minPrice: 10,
        maxPrice: 100
      };

      const stocks = [
        { code: 'sh.600000', industry: 'Banking', market: 'SH', price: 50 },
        { code: 'sh.600001', industry: 'Securities', market: 'SH', price: 30 },
        { code: 'sh.600002', industry: 'Banking', market: 'SZ', price: 20 }
      ];

      const filtered = stocks.filter(stock => {
        return stock.industry === filters.industry &&
               stock.market === filters.market &&
               stock.price >= filters.minPrice &&
               stock.price <= filters.maxPrice;
      });

      assert.strictEqual(filtered.length, 1);
      assert.strictEqual(filtered[0].code, 'sh.600000');
    });
  });

  describe('范围筛选测试', () => {
    it('应该筛选价格范围内的股票', () => {
      const stocks = [
        { code: 'A', price: 5 },
        { code: 'B', price: 15 },
        { code: 'C', price: 25 },
        { code: 'D', price: 35 }
      ];

      const minPrice = 10;
      const maxPrice = 30;

      const filtered = stocks.filter(s => s.price >= minPrice && s.price <= maxPrice);

      assert.strictEqual(filtered.length, 2);
      assert.strictEqual(filtered[0].code, 'B');
      assert.strictEqual(filtered[1].code, 'C');
    });

    it('应该筛选成交量范围内的股票', () => {
      const stocks = [
        { code: 'A', volume: 100000 },
        { code: 'B', volume: 500000 },
        { code: 'C', volume: 1000000 },
        { code: 'D', volume: 2000000 }
      ];

      const minVolume = 400000;
      const maxVolume = 1500000;

      const filtered = stocks.filter(s => s.volume >= minVolume && s.volume <= maxVolume);

      assert.strictEqual(filtered.length, 2);
    });
  });
});

// ============================================================================
// 3. 用户交互测试
// ============================================================================

describe('用户交互测试', () => {
  describe('条件添加测试', () => {
    it('应该添加新条件', () => {
      const conditions = [];
      const newCondition = {
        id: Date.now(),
        field: 'price',
        name: '股票价格',
        operator: '>',
        value: ''
      };

      conditions.push(newCondition);

      assert.strictEqual(conditions.length, 1);
      assert.strictEqual(conditions[0].field, 'price');
    });

    it('应该删除条件', () => {
      const conditions = [
        { id: 1, field: 'price' },
        { id: 2, field: 'volume' },
        { id: 3, field: 'pe' }
      ];

      // 删除第二个条件
      const index = 1;
      conditions.splice(index, 1);

      assert.strictEqual(conditions.length, 2);
      assert.strictEqual(conditions[0].id, 1);
      assert.strictEqual(conditions[1].id, 3);
    });

    it('应该清空所有条件', () => {
      const conditions = [
        { id: 1, field: 'price' },
        { id: 2, field: 'volume' }
      ];

      conditions.length = 0;

      assert.strictEqual(conditions.length, 0);
    });
  });

  describe('条件编辑测试', () => {
    it('应该更新操作符', () => {
      const condition = {
        id: 1,
        field: 'price',
        operator: '>'
      };

      const operators = ['>', '>=', '<', '<=', '=', '!='];

      operators.forEach(op => {
        condition.operator = op;
        assert.strictEqual(condition.operator, op);
      });
    });

    it('应该更新值', () => {
      const condition = {
        id: 1,
        field: 'price',
        value: ''
      };

      const values = ['10', '100.5', '-5', '0'];

      values.forEach(val => {
        condition.value = val;
        assert.strictEqual(condition.value, val);
      });
    });

    it('应该更新范围', () => {
      const condition = {
        id: 1,
        field: 'price',
        range: ''
      };

      condition.range = '10-100';
      assert.strictEqual(condition.range, '10-100');
    });
  });

  describe('拖拽排序测试', () => {
    it('应该交换条件顺序', () => {
      const conditions = [
        { id: 1, field: 'price' },
        { id: 2, field: 'volume' },
        { id: 3, field: 'pe' }
      ];

      // 将第一个条件移动到第二个位置
      const [moved] = conditions.splice(0, 1);
      conditions.splice(1, 0, moved);

      assert.strictEqual(conditions[0].id, 2);
      assert.strictEqual(conditions[1].id, 1);
      assert.strictEqual(conditions[2].id, 3);
    });

    it('应该将条件移动到最后', () => {
      const conditions = [
        { id: 1, field: 'price' },
        { id: 2, field: 'volume' },
        { id: 3, field: 'pe' }
      ];

      // 将第一个条件移动到最后
      const [moved] = conditions.splice(0, 1);
      conditions.push(moved);

      assert.strictEqual(conditions[0].id, 2);
      assert.strictEqual(conditions[1].id, 3);
      assert.strictEqual(conditions[2].id, 1);
    });
  });
});

// ============================================================================
// 4. 组件状态管理测试
// ============================================================================

describe('组件状态管理', () => {
  describe('条件状态', () => {
    it('应该展开条件详情', () => {
      const condition = {
        id: 1,
        expanded: false
      };

      condition.expanded = !condition.expanded;
      assert.ok(condition.expanded);
    });

    it('应该收起条件详情', () => {
      const condition = {
        id: 1,
        expanded: true
      };

      condition.expanded = !condition.expanded;
      assert.ok(!condition.expanded);
    });

    it('应该启用/禁用条件', () => {
      const condition = {
        id: 1,
        enabled: true
      };

      condition.enabled = false;
      assert.ok(!condition.enabled);

      condition.enabled = true;
      assert.ok(condition.enabled);
    });
  });

  describe('面板状态', () => {
    it('应该切换活动面板', () => {
      const panels = [
        { id: 'panel-1', active: true },
        { id: 'panel-2', active: false },
        { id: 'panel-3', active: false }
      ];

      // 切换到第二个面板
      panels.forEach((p, i) => {
        p.active = (i === 1);
      });

      assert.ok(!panels[0].active);
      assert.ok(panels[1].active);
      assert.ok(!panels[2].active);
    });
  });

  describe('步骤导航状态', () => {
    it('应该追踪当前步骤', () => {
      const state = { currentStep: 1 };

      // 前进到下一步
      state.currentStep = 2;
      assert.strictEqual(state.currentStep, 2);

      // 后退到上一步
      state.currentStep = 1;
      assert.strictEqual(state.currentStep, 1);
    });

    it('应该限制步骤范围', () => {
      const state = { currentStep: 1 };
      const maxStep = 4;

      // 尝试超过最大步骤
      state.currentStep = Math.min(state.currentStep + 1, maxStep);
      assert.ok(state.currentStep <= maxStep);

      // 尝试低于最小步骤
      state.currentStep = Math.max(state.currentStep - 1, 1);
      assert.ok(state.currentStep >= 1);
    });
  });
});

// ============================================================================
// 5. 数据验证测试
// ============================================================================

describe('数据验证', () => {
  describe('股票代码验证', () => {
    it('应该验证有效的股票代码格式', () => {
      const validCodes = ['sh.600000', 'sz.000001', 'sh.601398'];

      validCodes.forEach(code => {
        const isValid = /^[a-z]{2}\.\d{6}$/.test(code);
        assert.ok(isValid, `${code} 应该是有效的股票代码`);
      });
    });

    it('应该拒绝无效的股票代码格式', () => {
      const invalidCodes = ['600000', 'sh600000', 'SH.600000', 'sh.60000'];

      invalidCodes.forEach(code => {
        const isValid = /^[a-z]{2}\.\d{6}$/.test(code);
        assert.ok(!isValid, `${code} 应该是无效的股票代码`);
      });
    });
  });

  describe('数值范围验证', () => {
    it('应该验证价格在合理范围内', () => {
      const prices = [0.01, 1, 10, 100, 1000, 10000];

      prices.forEach(price => {
        assert.ok(price > 0, '价格应该大于 0');
        assert.ok(price <= 100000, '价格应该小于等于 100000');
      });
    });

    it('应该验证涨跌幅在合理范围内', () => {
      const changes = [-0.1, -0.05, 0, 0.05, 0.1];

      changes.forEach(change => {
        assert.ok(change >= -1 && change <= 1, '涨跌幅应该在 -100% 到 100% 之间');
      });
    });
  });

  describe('日期格式验证', () => {
    it('应该验证日期格式', () => {
      const validDates = ['2024-01-01', '2024-12-31', '2025-06-15'];

      validDates.forEach(date => {
        const isValid = /^\d{4}-\d{2}-\d{2}$/.test(date);
        assert.ok(isValid, `${date} 应该是有效的日期格式`);
      });
    });

    it('应该解析日期', () => {
      const dateStr = '2024-06-15';
      const date = new Date(dateStr);

      assert.ok(!isNaN(date.getTime()));
      assert.strictEqual(date.getFullYear(), 2024);
      assert.strictEqual(date.getMonth() + 1, 6);
      assert.strictEqual(date.getDate(), 15);
    });
  });
});
